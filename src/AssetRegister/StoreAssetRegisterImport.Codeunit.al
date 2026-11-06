codeunit 60127 "Store Asset Register Import"
{
    // Simple CSV import: a row that cannot be imported (no Description, or a Tag
    // Number already in use) is skipped and counted, and the rest carry on. Does
    // not support commas embedded inside quoted fields - keep the source data
    // plain-comma-separated.
    Permissions = tabledata "Store Asset Register" = RIM, tabledata "Store Asset Category" = RIM, tabledata "Fixed Asset" = R;

    procedure ImportFromCsv()
    var
        InStr: InStream;
        FileName: Text;
        Line: Text;
        LineNo: Integer;
        ImportedCount: Integer;
        SkippedCount: Integer;
        Fields: array[20] of Text[250];
    begin
        // Plain code throughout - no TryFunction. The rows are saved to the
        // database, and this server refuses to save inside a try function (the
        // page then shows "Something went wrong"). Each row is checked first
        // instead, and a row that cannot be imported is skipped and counted.
        if not UploadIntoStream(SelectFileTxt, '', 'CSV files (*.csv)|*.csv', FileName, InStr) then
            exit;

        while not InStr.EOS do begin
            InStr.ReadText(Line);
            LineNo += 1;

            // AL has no continue/break - the header row (line 1) and blank lines
            // are simply excluded from the body of the loop instead of skipped.
            if (LineNo > 1) and (DelChr(Line, '<>', ' ') <> '') then begin
                Clear(Fields);
                SplitCsvLine(Line, Fields);

                if RowCanBeImported(Fields) then begin
                    InsertRegisterRow(Fields);
                    ImportedCount += 1;
                end else
                    SkippedCount += 1;
            end;
        end;

        Message(ImportResultMsg, ImportedCount, SkippedCount);
    end;

    // A row is skipped if it has no Description, or its Tag Number is already
    // used - on another register row (including one imported earlier in this
    // same file) or on a Fixed Asset.
    local procedure RowCanBeImported(var Fields: array[20] of Text[250]): Boolean
    var
        AssetRegister: Record "Store Asset Register";
        FixedAsset: Record "Fixed Asset";
        TagNo: Code[30];
    begin
        if DelChr(Fields[2], '<>', ' ') = '' then
            exit(false);
        if Fields[6] = '' then
            exit(true);
        TagNo := CopyStr(Fields[6], 1, MaxStrLen(TagNo));
        AssetRegister.SetRange("Tag No.", TagNo);
        if not AssetRegister.IsEmpty() then
            exit(false);
        FixedAsset.SetRange("Tag No.", TagNo);
        exit(FixedAsset.IsEmpty());
    end;

    local procedure SplitCsvLine(Line: Text; var Fields: array[20] of Text[250])
    var
        Remaining: Text;
        CommaPos: Integer;
        i: Integer;
    begin
        Remaining := Line;
        i := 1;
        while (StrPos(Remaining, ',') > 0) and (i < ArrayLen(Fields)) do begin
            CommaPos := StrPos(Remaining, ',');
            Fields[i] := CopyStr(DelChr(CopyStr(Remaining, 1, CommaPos - 1), '<>', ' "'), 1, 250);
            Remaining := CopyStr(Remaining, CommaPos + 1);
            i += 1;
        end;
        Fields[i] := CopyStr(DelChr(Remaining, '<>', ' "'), 1, 250);
    end;

    local procedure InsertRegisterRow(var Fields: array[20] of Text[250])
    var
        AssetRegister: Record "Store Asset Register";
        Qty: Decimal;
        Cost: Decimal;
    begin
        AssetRegister.Init();
        if Fields[1] <> '' then
            AssetRegister.Category := CopyStr(EnsureCategoryExists(Fields[1]), 1, MaxStrLen(AssetRegister.Category));
        AssetRegister.Description := CopyStr(Fields[2], 1, MaxStrLen(AssetRegister.Description));
        AssetRegister."Location Code" := CopyStr(Fields[3], 1, MaxStrLen(AssetRegister."Location Code"));
        AssetRegister."Zone Code" := CopyStr(Fields[4], 1, MaxStrLen(AssetRegister."Zone Code"));
        AssetRegister."Shelf No." := CopyStr(Fields[5], 1, MaxStrLen(AssetRegister."Shelf No."));
        AssetRegister.Model := CopyStr(Fields[7], 1, MaxStrLen(AssetRegister.Model));
        AssetRegister."Serial No." := CopyStr(Fields[8], 1, MaxStrLen(AssetRegister."Serial No."));
        AssetRegister."Unit of Measure Code" := CopyStr(Fields[9], 1, MaxStrLen(AssetRegister."Unit of Measure Code"));
        if (Fields[10] <> '') and Evaluate(Qty, Fields[10]) then
            AssetRegister."Physical Count" := Qty;
        AssetRegister."Program Code" := CopyStr(Fields[11], 1, MaxStrLen(AssetRegister."Program Code"));
        if (Fields[12] <> '') and Evaluate(Cost, Fields[12]) then
            AssetRegister."Unit Cost" := Cost;
        AssetRegister.Status := ParseCondition(Fields[13]);
        AssetRegister.Remarks := CopyStr(Fields[14], 1, MaxStrLen(AssetRegister.Remarks));

        // The Tag Number was already checked for duplicates in RowCanBeImported.
        if Fields[6] <> '' then
            AssetRegister.Validate("Tag No.", CopyStr(Fields[6], 1, MaxStrLen(AssetRegister."Tag No.")));
        AssetRegister.Insert(true);
    end;

    // Lets a CSV mention a category that hasn't been set up yet in Asset
    // Categories, rather than rejecting the whole row for it. The stub entry
    // (description = code) can be renamed properly afterward on that page.
    local procedure EnsureCategoryExists(RawCode: Text[250]): Code[10]
    var
        AssetCategory: Record "Store Asset Category";
        NewCode: Code[10];
    begin
        NewCode := CopyStr(UpperCase(DelChr(RawCode, '<>', ' ')), 1, MaxStrLen(NewCode));
        if NewCode = '' then
            exit('');
        if not AssetCategory.Get(NewCode) then begin
            AssetCategory.Init();
            AssetCategory.Code := NewCode;
            AssetCategory.Description := NewCode;
            AssetCategory.Insert(true);
        end;
        exit(NewCode);
    end;

    local procedure ParseCondition(RawText: Text[250]): Enum "Store Asset Condition"
    var
        Upper: Text;
    begin
        Upper := UpperCase(RawText);
        if (StrPos(Upper, 'ACTIVE') > 0) or (StrPos(Upper, 'USABLE') > 0) then
            exit("Store Asset Condition"::Active);
        if (StrPos(Upper, 'DAMAGED') > 0) or (StrPos(Upper, 'BROKEN') > 0) then
            exit("Store Asset Condition"::Damaged);
        if StrPos(Upper, 'OBSOLETE') > 0 then
            exit("Store Asset Condition"::Obsolete);
        if StrPos(Upper, 'EXPIRED') > 0 then
            exit("Store Asset Condition"::Expired);
        if StrPos(Upper, 'REPAIR') > 0 then
            exit("Store Asset Condition"::RequiresRepair);
        exit("Store Asset Condition"::Unidentified);
    end;

    var
        SelectFileTxt: Label 'Select the CSV file to import';
        ImportResultMsg: Label '%1 rows imported, %2 skipped. Skipped rows are usually missing a Description, or have a Tag Number already used elsewhere.', Comment = '%1 = imported count, %2 = skipped count';
}
