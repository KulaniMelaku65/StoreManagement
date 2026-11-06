codeunit 60118 "Store Requisition Issue Mgt."
{
    Permissions = tabledata "Employee Items" = RIM, tabledata "Store Asset Register" = RM, tabledata "Store Inventory Register" = RM, tabledata "Fixed Asset" = R;

    // Called after a requisition finishes posting (Status = Posted). Gives every line
    // item on the requisition to the employee named on the header, via the existing
    // Employee Items custody ledger - one row per line, matching how that ledger
    // already tracks a single item/asset per employee (it has no quantity field, so
    // bulk consumable lines get one ledger row for the line, not one per unit).
    procedure CreateEmployeeItemsForRequisition(var RequisitionHeader: Record "PROC-Store Requistion Header")
    var
        RequisitionLine: Record "PROC-Store Requistion Lines";
        EmployeeItem: Record "Employee Items";
    begin
        if RequisitionHeader."Employee No." = '' then
            exit;

        RequisitionLine.SetRange("Requistion No", RequisitionHeader."No.");
        if not RequisitionLine.FindSet() then
            exit;

        repeat
            // Clear, not Init: Init leaves the primary key alone, so the second line
            // would reuse the first line's Line No. and fail to insert. The row is
            // filled in completely and inserted once below, so a failure can never
            // leave a half-filled custody row behind.
            Clear(EmployeeItem);
            EmployeeItem."Employee No." := RequisitionHeader."Employee No.";
            // Requisition lines are Item or Minor Asset. A Minor Asset linked to a
            // Fixed Asset card is a "Fixed Asset" on Employee Items (looked up by
            // its Fixed Asset No.). One that only exists on the Asset Register has
            // no card to look up, so it is recorded by its tag with no type.
            if RequisitionLine.Type = RequisitionLine.Type::"Minor Asset" then begin
                if HasFixedAssetCard(RequisitionLine."Tag No.") then begin
                    EmployeeItem.Validate("Item Type", EmployeeItem."Item Type"::"Fixed Asset");
                    EmployeeItem.Validate("Item No.", RequisitionLine."No.");
                end else begin
                    EmployeeItem."Item Type" := EmployeeItem."Item Type"::" ";
                    EmployeeItem."Item No." := CopyStr(RequisitionLine."Tag No.", 1, MaxStrLen(EmployeeItem."Item No."));
                end;
            end else begin
                EmployeeItem.Validate("Item Type", EmployeeItem."Item Type"::Item);
                EmployeeItem.Validate("Item No.", RequisitionLine."No.");
            end;
            if EmployeeItem.Description = '' then
                EmployeeItem.Description := CopyStr(RequisitionLine.Description, 1, MaxStrLen(EmployeeItem.Description));
            EmployeeItem."Start Date" := Today();
            EmployeeItem."Source Doc. No." := RequisitionHeader."No.";
            if RequisitionLine."Tag No." <> '' then
                EmployeeItem."Tag No." := RequisitionLine."Tag No.";
            // What the history needs beyond Fanisi's own columns: who the person is,
            // how many, where it left from, and who approved it.
            EmployeeItem."Employee Name" := RequisitionHeader."Employee Name";
            if RequisitionLine."Tag No." <> '' then
                EmployeeItem.Quantity := 1
            else
                EmployeeItem.Quantity := QuantityIssuedFor(RequisitionLine);
            EmployeeItem."Issuing Store" := CopyStr(RequisitionLine."Issuing Store", 1, MaxStrLen(EmployeeItem."Issuing Store"));
            EmployeeItem."Approved By" := RequisitionHeader."Approved By";
            EmployeeItem.Insert(true);
            EmployeeItem.AllocateItem();

            if RequisitionLine."Tag No." <> '' then
                MarkTagIssued(RequisitionLine."Tag No.", RequisitionHeader."Employee Name")
            else
                // No specific tagged unit - this is a consumable draw against the
                // Inventory Register (paper, pens, toner...), and it's gone for
                // good once issued, unlike a Fixed Asset. Employee Items above
                // still records who received it, for accountability, but nothing
                // is ever expected back for these.
                if RequisitionLine.Type = RequisitionLine.Type::Item then
                    ConsumeInventoryStock(RequisitionLine."No.", QuantityIssuedFor(RequisitionLine));
        until RequisitionLine.Next() = 0;
    end;

    procedure HasFixedAssetCard(TagNo: Code[30]): Boolean
    var
        AssetRegister: Record "Store Asset Register";
        FixedAsset: Record "Fixed Asset";
    begin
        if TagNo = '' then
            exit(false);
        AssetRegister.SetRange("Tag No.", TagNo);
        if not AssetRegister.FindFirst() then
            exit(false);
        if AssetRegister."Fixed Asset No." = '' then
            exit(false);
        exit(FixedAsset.Get(AssetRegister."Fixed Asset No."));
    end;

    // The base requisition has several quantity fields (Quantity, Quantity
    // Requested, Quantity To Issue, Quantity Issued). Use the most specific one
    // that has a value: what was actually issued, else what was to be issued,
    // else what was requested, else the plain Quantity.
    local procedure QuantityIssuedFor(RequisitionLine: Record "PROC-Store Requistion Lines"): Decimal
    begin
        if RequisitionLine."Quantity Issued" > 0 then
            exit(RequisitionLine."Quantity Issued");
        if RequisitionLine."Quantity To Issue" > 0 then
            exit(RequisitionLine."Quantity To Issue");
        if RequisitionLine."Quantity Requested" > 0 then
            exit(RequisitionLine."Quantity Requested");
        exit(RequisitionLine.Quantity);
    end;

    local procedure ConsumeInventoryStock(ItemNo: Code[20]; QtyToConsume: Decimal)
    var
        InventoryRegister: Record "Store Inventory Register";
        RemainingQty: Decimal;
        DeductNow: Decimal;
    begin
        if (ItemNo = '') or (QtyToConsume <= 0) then
            exit;
        RemainingQty := QtyToConsume;
        // Deduct from whichever Inventory Register rows for this Item still have
        // stock, oldest entries first, until the requested quantity is used up.
        // Both Quantity and Physical Count move together here - we know for
        // certain this left the store, so there's no variance from this alone;
        // Variance is only for drift a later physical recount discovers.
        InventoryRegister.SetRange("Item No.", ItemNo);
        InventoryRegister.SetFilter("Physical Count", '>0');
        if InventoryRegister.FindSet(true) then
            repeat
                if RemainingQty > 0 then begin
                    DeductNow := RemainingQty;
                    if DeductNow > InventoryRegister."Physical Count" then
                        DeductNow := InventoryRegister."Physical Count";
                    InventoryRegister."Physical Count" -= DeductNow;
                    InventoryRegister.Quantity -= DeductNow;
                    InventoryRegister.Modify(true);
                    RemainingQty -= DeductNow;
                end;
            until InventoryRegister.Next() = 0;
    end;

    local procedure MarkTagIssued(TagNo: Code[30]; EmployeeName: Text[100])
    var
        AssetRegister: Record "Store Asset Register";
    begin
        AssetRegister.SetRange("Tag No.", TagNo);
        if not AssetRegister.FindFirst() then
            exit;
        // Re-check availability here too - the line's own OnValidate already
        // checked this when the tag was picked, but time may have passed
        // between then and actually posting the requisition.
        if AssetRegister."Availability Status" <> AssetRegister."Availability Status"::Available then
            exit;
        AssetRegister."Availability Status" := AssetRegister."Availability Status"::Issued;
        AssetRegister."Issued Date" := Today();
        AssetRegister."Assigned To" := EmployeeName;
        AssetRegister."Return Date" := 0D;
        AssetRegister."Return To" := '';
        AssetRegister.Modify(true);
    end;
}
