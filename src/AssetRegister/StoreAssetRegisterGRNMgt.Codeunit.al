codeunit 60142 "Store Asset Register GRN Mgt."
{
    // Closes the loop from GRN back to the Asset Register: Finance creates one
    // Fixed Asset card per purchase regardless of quantity (e.g. 12 laptops on
    // one PO line, one Fixed Asset card), and the quantity only ever lives on
    // the Purchase/GRN line. Store GRN Line Split Mgt. splits that one 12-unit
    // GRN line into 12 separate one-unit lines at generation time; once the GRN
    // is confirmed, CreateRegisterEntriesFromGRN turns each of those lines into
    // its own tagged Asset Register entry.
    Permissions = tabledata "Custom GRN Lines" = RM, tabledata "Fixed Asset" = R, tabledata "Store Asset Register" = RIM, tabledata "Store Asset Category" = RIM, tabledata "Store Asset Type" = RIM;

    procedure CreateRegisterEntriesFromGRN(GRNHeader: Record "Custom GRN Header")
    var
        GRNLine: Record "Custom GRN Lines";
        CreatedCount: Integer;
    begin
        GRNLine.SetRange("Document No.", GRNHeader."No.");
        GRNLine.SetRange(Type, GRNLine.Type::"Fixed Asset");
        GRNLine.SetFilter("Quantity To Receive", '>0');
        GRNLine.SetRange("Register Entry No.", 0);
        if GRNLine.FindSet(true) then
            repeat
                CreateRegisterEntry(GRNHeader, GRNLine);
                CreatedCount += 1;
            until GRNLine.Next() = 0;
    end;

    // Plain procedure, not a [TryFunction]: this writes to the database, and
    // writing inside a try function is refused on servers that disable it. An
    // error here now stops Confirm GRN with a readable message instead.
    local procedure CreateRegisterEntry(GRNHeader: Record "Custom GRN Header"; var GRNLine: Record "Custom GRN Lines")
    var
        AssetRegister: Record "Store Asset Register";
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.Get(GRNLine."No.");

        AssetRegister.Init();
        if GRNLine.Category <> '' then
            AssetRegister.Category := CopyStr(EnsureCategoryExists(GRNLine.Category), 1, MaxStrLen(AssetRegister.Category))
        else
            if FixedAsset."FA Class Code" <> '' then
                AssetRegister.Category := CopyStr(EnsureCategoryExists(FixedAsset."FA Class Code"), 1, MaxStrLen(AssetRegister.Category));
        if GRNLine."Asset Type" <> '' then
            AssetRegister."Type" := CopyStr(EnsureTypeExists(GRNLine."Asset Type"), 1, MaxStrLen(AssetRegister."Type"));
        AssetRegister."Location Code" := GRNLine."Location Code";
        // Description comes from the Asset Type (e.g. "Mobile Phone"), else the Asset
        // Class, as set up on the Asset Types / Asset Categories lists. The long
        // purchase-line text goes to Model (set on the GRN line), so the register
        // stays tidy.
        AssetRegister.Description := CopyStr(DescriptionFor(AssetRegister.Category, AssetRegister."Type", GRNLine.Description), 1, MaxStrLen(AssetRegister.Description));
        AssetRegister.Model := CopyStr(GRNLine.Model, 1, MaxStrLen(AssetRegister.Model));
        AssetRegister."Serial No." := CopyStr(GRNLine."Serial No.", 1, MaxStrLen(AssetRegister."Serial No."));
        AssetRegister."Unit of Measure Code" := CopyStr(GRNLine."Unit Of Measure", 1, MaxStrLen(AssetRegister."Unit of Measure Code"));
        AssetRegister."Physical Count" := GRNLine."Quantity To Receive";
        AssetRegister."Unit Cost" := GRNLine."Unit Cost";
        AssetRegister."Fixed Asset No." := GRNLine."No.";
        AssetRegister."PO No." := GRNHeader."Order No.";
        AssetRegister."Vendor No." := GRNHeader."Vendor No.";
        AssetRegister."Procured Date" := GRNHeader."Date Received";
        AssetRegister.Insert(true);

        GRNLine."Register Entry No." := AssetRegister."Entry No.";
        // No triggers: only our own link field changes, and Fanisi's Custom GRN
        // Lines triggers (which we can't see) fail here with an unknown-type error.
        GRNLine.Modify(false);
    end;

    local procedure DescriptionFor(CategoryCode: Code[10]; TypeCode: Code[10]; Fallback: Text): Text
    var
        AssetType: Record "Store Asset Type";
        AssetCategory: Record "Store Asset Category";
    begin
        if (TypeCode <> '') and AssetType.Get(TypeCode) and (AssetType.Description <> '') then
            exit(AssetType.Description);
        if (CategoryCode <> '') and AssetCategory.Get(CategoryCode) and (AssetCategory.Description <> '') then
            exit(AssetCategory.Description);
        exit(Fallback);
    end;

    local procedure EnsureCategoryExists(RawCode: Code[10]): Code[10]
    var
        AssetCategory: Record "Store Asset Category";
    begin
        if not AssetCategory.Get(RawCode) then begin
            AssetCategory.Init();
            AssetCategory.Code := RawCode;
            AssetCategory.Description := RawCode;
            AssetCategory.Insert(true);
        end;
        exit(RawCode);
    end;

    local procedure EnsureTypeExists(RawCode: Code[10]): Code[10]
    var
        AssetType: Record "Store Asset Type";
    begin
        if not AssetType.Get(RawCode) then begin
            AssetType.Init();
            AssetType.Code := RawCode;
            AssetType.Description := RawCode;
            AssetType.Insert(true);
        end;
        exit(RawCode);
    end;
}
