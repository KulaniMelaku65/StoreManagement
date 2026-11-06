codeunit 60173 "Store Asset Transfer Mgt."
{
    Permissions = tabledata "Store Asset Transfer" = RM, tabledata "Store Asset Register" = RM, tabledata "Employee Items" = RIM, tabledata Employee = R, tabledata "Fixed Asset" = R;

    // Step 1 - the Store Manager confirms the transfer. Never the person who raised it.
    procedure Confirm(var AssetTransfer: Record "Store Asset Transfer")
    var
        StoreReqApprovalMgt: Codeunit "Store Req. Approval Mgt.";
    begin
        AssetTransfer.TestField(Status, AssetTransfer.Status::Open);
        AssetTransfer.TestField("Tag No.");
        if (AssetTransfer."To Location Code" = '') and (AssetTransfer."To Employee No." = '') then
            Error(NothingToChangeErr);
        if not StoreReqApprovalMgt.IsStoreManager() then
            Error(NotManagerErr);
        if AssetTransfer.SystemCreatedBy = UserSecurityId() then
            Error(OwnTransferErr);

        AssetTransfer.Status := AssetTransfer.Status::Confirmed;
        AssetTransfer."Confirmed By" := CopyStr(UserId(), 1, MaxStrLen(AssetTransfer."Confirmed By"));
        AssetTransfer."Confirmed Date" := Today();
        AssetTransfer.Modify(true);
        Message(ConfirmedMsg, AssetTransfer."No.");
    end;

    // Step 2 - the store keeper carries it out: the Asset Register row moves,
    // and a change of holder closes the old custody row and opens a new one so
    // the unit's history reads A, then B, then C.
    procedure Transfer(var AssetTransfer: Record "Store Asset Transfer")
    var
        AssetRegister: Record "Store Asset Register";
        HolderChange: Boolean;
    begin
        AssetTransfer.TestField(Status, AssetTransfer.Status::Confirmed);

        AssetRegister.SetRange("Tag No.", AssetTransfer."Tag No.");
        AssetRegister.FindFirst();
        if AssetRegister."Availability Status" = AssetRegister."Availability Status"::Disposed then
            Error(DisposedErr, AssetTransfer."Tag No.");

        HolderChange := AssetTransfer."To Employee No." <> '';
        if HolderChange then begin
            // Handing over to another person only makes sense for a unit someone
            // already holds. Issuing a unit from the store is a store requisition.
            if AssetRegister."Availability Status" <> AssetRegister."Availability Status"::Issued then
                Error(NotIssuedErr, AssetTransfer."Tag No.");
            CloseOpenCustody(AssetTransfer."Tag No.");
            OpenNewCustody(AssetTransfer);
            AssetRegister."Assigned To" := AssetTransfer."To Employee Name";
            AssetRegister."Issued Date" := Today();
            AssetRegister."Reassigned Date" := Today();
            AssetRegister."Reassigned To" := AssetTransfer."To Employee Name";
        end;

        if AssetTransfer."To Location Code" <> '' then
            AssetRegister."Location Code" := AssetTransfer."To Location Code";
        if AssetTransfer."To Zone Code" <> '' then
            AssetRegister."Zone Code" := AssetTransfer."To Zone Code";
        if AssetTransfer."To Shelf No." <> '' then
            AssetRegister."Shelf No." := AssetTransfer."To Shelf No.";
        AssetRegister.Modify(true);

        AssetTransfer.Status := AssetTransfer.Status::Transferred;
        AssetTransfer."Transferred By" := CopyStr(UserId(), 1, MaxStrLen(AssetTransfer."Transferred By"));
        AssetTransfer."Transferred Date" := Today();
        AssetTransfer.Modify(true);
        Message(TransferredMsg, AssetTransfer."Tag No.");
    end;

    // The previous holder hands it over: their custody row is closed today.
    local procedure CloseOpenCustody(TagNo: Code[30])
    var
        EmployeeItem: Record "Employee Items";
    begin
        EmployeeItem.SetRange("Tag No.", TagNo);
        EmployeeItem.SetRange(Allocated, true);
        EmployeeItem.SetRange(Returned, false);
        if EmployeeItem.FindSet(true) then
            repeat
                if EmployeeItem."End Date" = 0D then
                    EmployeeItem."End Date" := Today();
                EmployeeItem.ReturnItem();
            until EmployeeItem.Next() = 0;
    end;

    local procedure OpenNewCustody(AssetTransfer: Record "Store Asset Transfer")
    var
        EmployeeItem: Record "Employee Items";
        StoreRequisitionIssueMgt: Codeunit "Store Requisition Issue Mgt.";
    begin
        Clear(EmployeeItem);
        EmployeeItem."Employee No." := AssetTransfer."To Employee No.";
        // Same recording as a store issue: a Fixed Asset when the unit has a card,
        // otherwise by its tag alone.
        if StoreRequisitionIssueMgt.HasFixedAssetCard(AssetTransfer."Tag No.") then begin
            EmployeeItem.Validate("Item Type", EmployeeItem."Item Type"::"Fixed Asset");
            EmployeeItem.Validate("Item No.", AssetTransfer."Fixed Asset No.");
        end else begin
            EmployeeItem."Item Type" := EmployeeItem."Item Type"::" ";
            EmployeeItem."Item No." := CopyStr(AssetTransfer."Tag No.", 1, MaxStrLen(EmployeeItem."Item No."));
        end;
        if EmployeeItem.Description = '' then
            EmployeeItem.Description := CopyStr(AssetTransfer.Description + ' ' + AssetTransfer.Model, 1, MaxStrLen(EmployeeItem.Description));
        EmployeeItem."Start Date" := Today();
        EmployeeItem."Source Doc. No." := CopyStr(AssetTransfer."No.", 1, MaxStrLen(EmployeeItem."Source Doc. No."));
        EmployeeItem."Tag No." := AssetTransfer."Tag No.";
        EmployeeItem."Employee Name" := AssetTransfer."To Employee Name";
        EmployeeItem.Quantity := 1;
        EmployeeItem."Issuing Store" := AssetTransfer."From Location Code";
        EmployeeItem."Approved By" := AssetTransfer."Confirmed By";
        EmployeeItem.Insert(true);
        EmployeeItem.AllocateItem();
    end;

    var
        NothingToChangeErr: Label 'Choose a new location, a new employee, or both before confirming.';
        NotManagerErr: Label 'Only a Store Manager can confirm an asset transfer.';
        OwnTransferErr: Label 'You cannot confirm an asset transfer that you raised yourself.';
        NotIssuedErr: Label 'Tag No. %1 is not issued to anyone, so it cannot be handed to another employee. Issue it from a store requisition, or change the location only.', Comment = '%1 = tag number';
        DisposedErr: Label 'Tag No. %1 has been disposed and cannot be transferred.', Comment = '%1 = tag number';
        ConfirmedMsg: Label 'Asset transfer %1 is confirmed. The store keeper can now carry it out.', Comment = '%1 = transfer number';
        TransferredMsg: Label 'Tag No. %1 has been transferred.', Comment = '%1 = tag number';
}
