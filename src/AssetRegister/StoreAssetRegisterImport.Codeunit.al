codeunit 60127 "Store Asset Register Import"
{
    // Simple, defensive CSV import: one bad row shouldn't lose the rest of the
    // batch, so each row runs through a TryFunction and gets skipped rather than
    // aborting the whole file. Does not support commas embedded inside quoted
    // fields - keep the source data plain-comma-separated.
    Permissions = tabledata "Store Asset Register" = RIM, tabledata "Store Asset Category" = RIM;

    procedure ImportFromCsv()
    var
        InStr: InStream;
        FileName: Text;
    begin
        // UploadIntoStream is a client interaction (it shows the browser file
        // picker) and must NOT run inside a TryFunction - TryFunction's isolated
        // execution context doesn't support that client round-trip, and the
        // mismatch surfaces as a raw platform crash page instead of a normal,
        // catchable AL error. The upload happens here, in the plain procedure;
        // only the row-by-row parsing/inserting below is wrapped in a TryFunction.
        if not UploadIntoStream(SelectFileTxt, '', 'CSV files (*.csv)|*.csv', FileName, InStr) then
            exit;

        // Wrapped so a failure shows an actual, readable reason instead of a
        // dead-end platform error page.
        if not TryImportFromCsv(InStr) then
            Message(DiagnosticFailedMsg, GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryImportFromCsv(var InStr: InStream)
    var
        Line: Text;
        LineNo: Integer;
        ImportedCount: Integer;
        SkippedCount: Integer;
        Fields: array[20] of Text[250];
    begin
        while not InStr.EOS do begin
            InStr.ReadText(Line);
            LineNo += 1;

            // AL has no continue/break - the header row (line 1) and blank lines
            // are simply excluded from the body of the loop instead of skipped.
            if (LineNo > 1) and (DelChr(Line, '<>', ' ') <> '') then begin
                Clear(Fields);
                SplitCsvLine(Line, Fields);

                if TryInsertRegisterRow(Fields) then
                    ImportedCount += 1
                else
                    SkippedCount += 1;
            end;
        end;

        Message(ImportResultMsg, ImportedCount, SkippedCount);
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

    [TryFunction]
    local procedure TryInsertRegisterRow(var Fields: array[20] of Text[250])
    var
        AssetRegister: Record "Store Asset Register";
        Qty: Decimal;
        Cost: Decimal;
    begin
        AssetRegister.Init();
        if Fields[1] <> '' then
            AssetRegister.Category := CopyStr(EnsureCategoryExists(Fields[1]), 1, MaxStrLen(AssetRegister.Category));
        AssetRegister.Description := CopyStr(Fields[2], 1, MaxStrLen(AssetRegister.Description));
        AssetRegister.TestField(Description);
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

        // Validate Tag No. before inserting - if it's a duplicate, this raises
        // an error and the row is skipped cleanly with nothing left behind. Doing
        // the uniqueness check after Insert would leave an orphaned tagless row
        // in the table even though the import reports it as "skipped".
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
        DiagnosticFailedMsg: Label 'Import failed: %1', Comment = '%1 = the underlying error text';
}
