codeunit 60110 "Store Inv. Register Import"
{
    // Column order: Category, Program, Description, UoM, Quantity, Unit Cost,
    // Physical Count, Location, Status, Remarks. Same as the Asset Register
    // import - a row without a Description is skipped and counted.
    Permissions = tabledata "Store Inventory Register" = RIM, tabledata "Store Inventory Category" = RIM;

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
        // Plain code, no TryFunction: see Store Asset Register Import for why.
        if not UploadIntoStream(SelectFileTxt, '', 'CSV files (*.csv)|*.csv', FileName, InStr) then
            exit;

        while not InStr.EOS do begin
            InStr.ReadText(Line);
            LineNo += 1;

            if (LineNo > 1) and (DelChr(Line, '<>', ' ') <> '') then begin
                Clear(Fields);
                SplitCsvLine(Line, Fields);

                // A row without a Description is skipped.
                if DelChr(Fields[3], '<>', ' ') <> '' then begin
                    InsertRegisterRow(Fields);
                    ImportedCount += 1;
                end else
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

    local procedure InsertRegisterRow(var Fields: array[20] of Text[250])
    var
        InventoryRegister: Record "Store Inventory Register";
        Qty: Decimal;
        Cost: Decimal;
    begin
        InventoryRegister.Init();
        if Fields[1] <> '' then
            InventoryRegister.Category := CopyStr(EnsureCategoryExists(Fields[1]), 1, MaxStrLen(InventoryRegister.Category));
        InventoryRegister."Program Code" := CopyStr(Fields[2], 1, MaxStrLen(InventoryRegister."Program Code"));
        InventoryRegister.Description := CopyStr(Fields[3], 1, MaxStrLen(InventoryRegister.Description));
        InventoryRegister."Unit of Measure Code" := CopyStr(Fields[4], 1, MaxStrLen(InventoryRegister."Unit of Measure Code"));
        if (Fields[5] <> '') and Evaluate(Qty, Fields[5]) then
            InventoryRegister.Quantity := Qty;
        if (Fields[6] <> '') and Evaluate(Cost, Fields[6]) then
            InventoryRegister."Unit Cost" := Cost;
        if (Fields[7] <> '') and Evaluate(Qty, Fields[7]) then
            InventoryRegister."Physical Count" := Qty;
        InventoryRegister."Location Code" := CopyStr(Fields[8], 1, MaxStrLen(InventoryRegister."Location Code"));
        InventoryRegister.Status := ParseCondition(Fields[9]);
        InventoryRegister.Remarks := CopyStr(Fields[10], 1, MaxStrLen(InventoryRegister.Remarks));
        InventoryRegister.Insert(true);
    end;

    local procedure EnsureCategoryExists(RawCode: Text[250]): Code[10]
    var
        InventoryCategory: Record "Store Inventory Category";
        NewCode: Code[10];
    begin
        NewCode := CopyStr(UpperCase(DelChr(RawCode, '<>', ' ')), 1, MaxStrLen(NewCode));
        if NewCode = '' then
            exit('');
        if not InventoryCategory.Get(NewCode) then begin
            InventoryCategory.Init();
            InventoryCategory.Code := NewCode;
            InventoryCategory.Description := NewCode;
            InventoryCategory.Insert(true);
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
        ImportResultMsg: Label '%1 rows imported, %2 skipped. Skipped rows are usually missing a Description.', Comment = '%1 = imported count, %2 = skipped count';
}
