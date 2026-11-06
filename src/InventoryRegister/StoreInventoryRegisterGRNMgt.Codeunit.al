codeunit 60157 "Store Inv. Register GRN Mgt."
{
    // Mirrors Store Asset Register GRN Mgt., but for Item (consumable) lines:
    // once an Item GRN line - already split to one unit per line by Store GRN
    // Line Split Mgt. - is confirmed, this creates its own Inventory Register
    // entry, one row per unit, each carrying its own share of the cost.
    Permissions = tabledata "Custom GRN Lines" = RM, tabledata Item = R, tabledata "Store Inventory Register" = RIM, tabledata "Store Inventory Category" = RIM;

    procedure CreateInventoryEntriesFromGRN(GRNHeader: Record "Custom GRN Header")
    var
        GRNLine: Record "Custom GRN Lines";
        CreatedCount: Integer;
    begin
        GRNLine.SetRange("Document No.", GRNHeader."No.");
        GRNLine.SetRange(Type, GRNLine.Type::Item);
        GRNLine.SetFilter("Quantity To Receive", '>0');
        GRNLine.SetRange("Inventory Entry No.", 0);
        if GRNLine.FindSet(true) then
            repeat
                CreateInventoryEntry(GRNHeader, GRNLine);
                CreatedCount += 1;
            until GRNLine.Next() = 0;
    end;

    // Plain procedure, not a [TryFunction]: see Store Asset Register GRN Mgt.
    local procedure CreateInventoryEntry(GRNHeader: Record "Custom GRN Header"; var GRNLine: Record "Custom GRN Lines")
    var
        InventoryRegister: Record "Store Inventory Register";
        Item: Record Item;
    begin
        Item.Get(GRNLine."No.");

        InventoryRegister.Init();
        if GRNLine.Category <> '' then
            InventoryRegister.Category := CopyStr(EnsureCategoryExists(GRNLine.Category), 1, MaxStrLen(InventoryRegister.Category))
        else
            if Item."Item Category Code" <> '' then
                // Item Category Code is Code[20] but Store Inventory Category's own
                // Code is Code[10] - truncate explicitly here rather than let it
                // happen silently at the parameter boundary.
                InventoryRegister.Category := CopyStr(EnsureCategoryExists(CopyStr(Item."Item Category Code", 1, 10)), 1, MaxStrLen(InventoryRegister.Category));
        InventoryRegister."Location Code" := GRNLine."Location Code";
        // Description is the Item card's own name, not the purchase-line text.
        if Item.Description <> '' then
            InventoryRegister.Description := CopyStr(Item.Description, 1, MaxStrLen(InventoryRegister.Description))
        else
            InventoryRegister.Description := CopyStr(GRNLine.Description, 1, MaxStrLen(InventoryRegister.Description));
        InventoryRegister."Unit of Measure Code" := CopyStr(GRNLine."Unit Of Measure", 1, MaxStrLen(InventoryRegister."Unit of Measure Code"));
        // Physical Count starts equal to the received Quantity - no variance yet,
        // since nothing has actually been counted or consumed since receipt.
        InventoryRegister.Quantity := GRNLine."Quantity To Receive";
        InventoryRegister."Physical Count" := GRNLine."Quantity To Receive";
        InventoryRegister."Unit Cost" := GRNLine."Unit Cost";
        InventoryRegister."Item No." := GRNLine."No.";
        InventoryRegister.Insert(true);

        GRNLine."Inventory Entry No." := InventoryRegister."Entry No.";
        // No triggers: see Store Asset Register GRN Mgt.
        GRNLine.Modify(false);
    end;

    local procedure EnsureCategoryExists(RawCode: Code[10]): Code[10]
    var
        InventoryCategory: Record "Store Inventory Category";
    begin
        if not InventoryCategory.Get(RawCode) then begin
            InventoryCategory.Init();
            InventoryCategory.Code := RawCode;
            InventoryCategory.Description := RawCode;
            InventoryCategory.Insert(true);
        end;
        exit(RawCode);
    end;
}
