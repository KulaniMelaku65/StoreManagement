codeunit 60177 "Store Asset Custody Link Mgt."
{
    // One-off take-on of assets employees already had before the system went live.
    // Those rows were loaded onto the Asset Register with the holder's name typed
    // into "Assigned To", but nothing else: no Employee Items custody row and the
    // Availability still "Available". Return, transfer and the issue history all
    // work off the custody row, so this creates it - the same way a posted store
    // requisition does - for every row whose name matches exactly one employee.
    //
    // Safe to run again: a row that is linked becomes "Issued" and is not picked
    // up a second time. Rows that could not be matched are left as they are, so
    // the name can be corrected (or replaced with the Employee No.) and re-run.
    Permissions = tabledata "Store Asset Register" = RM, tabledata "Employee Items" = RIM, tabledata Employee = R, tabledata "Fixed Asset" = R;

    procedure LinkAssignedAssets(var UnmatchedCount: Integer)
    var
        AssetRegister: Record "Store Asset Register";
        ToProcess: Record "Store Asset Register" temporary;
        NameToEmployee: Dictionary of [Text, Text];
        AmbiguousNames: List of [Text];
        EmployeeNo: Code[20];
        LinkedCount: Integer;
        NotFoundCount: Integer;
        AmbiguousCount: Integer;
        NoTagCount: Integer;
        NameKey: Text;
    begin
        UnmatchedCount := 0;
        if not Confirm(ConfirmQst) then
            exit;

        BuildEmployeeIndex(NameToEmployee, AmbiguousNames);

        // Snapshot first: linking changes Availability Status, which is part of
        // the filter, and modifying a filtered field inside the same loop can
        // make the loop skip rows.
        AssetRegister.SetRange("Availability Status", AssetRegister."Availability Status"::Available);
        AssetRegister.SetFilter("Assigned To", '<>%1', '');
        if AssetRegister.FindSet() then
            repeat
                ToProcess := AssetRegister;
                ToProcess.Insert();
            until AssetRegister.Next() = 0;

        if ToProcess.FindSet() then
            repeat
                AssetRegister.Get(ToProcess."Entry No.");
                NameKey := Normalize(AssetRegister."Assigned To");
                if AssetRegister."Tag No." = '' then
                    // Return and transfer find the custody row by its tag.
                    NoTagCount += 1
                else
                    if AmbiguousNames.Contains(NameKey) then
                        AmbiguousCount += 1
                    else
                        if not NameToEmployee.ContainsKey(NameKey) then
                            NotFoundCount += 1
                        else begin
                            EmployeeNo := CopyStr(NameToEmployee.Get(NameKey), 1, MaxStrLen(EmployeeNo));
                            LinkRow(AssetRegister, EmployeeNo);
                            LinkedCount += 1;
                        end;
            until ToProcess.Next() = 0;

        UnmatchedCount := NotFoundCount + AmbiguousCount + NoTagCount;
        Message(ResultMsg, LinkedCount, NotFoundCount, AmbiguousCount, NoTagCount);
    end;

    // Used by the "Assigned To Name Matching" worksheet once a person has
    // confirmed which employee a typed name means. Links every still-Available
    // asset carrying exactly that Assigned To text. Returns how many were linked.
    procedure LinkAssetsForName(AssignedTo: Text[100]; EmployeeNo: Code[20]; var NoTagCount: Integer): Integer
    var
        AssetRegister: Record "Store Asset Register";
        ToProcess: Record "Store Asset Register" temporary;
        LinkedCount: Integer;
    begin
        if (AssignedTo = '') or (EmployeeNo = '') then
            exit(0);
        AssetRegister.SetRange("Availability Status", AssetRegister."Availability Status"::Available);
        AssetRegister.SetRange("Assigned To", AssignedTo);
        if AssetRegister.FindSet() then
            repeat
                ToProcess := AssetRegister;
                ToProcess.Insert();
            until AssetRegister.Next() = 0;

        if ToProcess.FindSet() then
            repeat
                AssetRegister.Get(ToProcess."Entry No.");
                if AssetRegister."Tag No." = '' then
                    NoTagCount += 1
                else begin
                    LinkRow(AssetRegister, EmployeeNo);
                    LinkedCount += 1;
                end;
            until ToProcess.Next() = 0;
        exit(LinkedCount);
    end;

    local procedure LinkRow(var AssetRegister: Record "Store Asset Register"; EmployeeNo: Code[20])
    var
        EmployeeItem: Record "Employee Items";
        StoreRequisitionIssueMgt: Codeunit "Store Requisition Issue Mgt.";
        StoreEmployeeNameMgt: Codeunit "Store Employee Name Mgt.";
        EmployeeName: Text[100];
        StartDate: Date;
    begin
        EmployeeName := StoreEmployeeNameMgt.FullName(EmployeeNo);
        StartDate := AssetRegister."Issued Date";
        if StartDate = 0D then
            StartDate := Today();

        // Don't open a second custody row if one already exists for this tag.
        EmployeeItem.SetRange("Tag No.", AssetRegister."Tag No.");
        EmployeeItem.SetRange(Allocated, true);
        EmployeeItem.SetRange(Returned, false);
        if EmployeeItem.IsEmpty() then begin
            Clear(EmployeeItem);
            EmployeeItem."Employee No." := EmployeeNo;
            // Same recording as a store issue: a Fixed Asset when the unit has a
            // card, otherwise by its tag alone.
            if StoreRequisitionIssueMgt.HasFixedAssetCard(AssetRegister."Tag No.") then begin
                EmployeeItem.Validate("Item Type", EmployeeItem."Item Type"::"Fixed Asset");
                EmployeeItem.Validate("Item No.", AssetRegister."Fixed Asset No.");
            end else begin
                EmployeeItem."Item Type" := EmployeeItem."Item Type"::" ";
                EmployeeItem."Item No." := CopyStr(AssetRegister."Tag No.", 1, MaxStrLen(EmployeeItem."Item No."));
            end;
            if EmployeeItem.Description = '' then
                EmployeeItem.Description := CopyStr(DelChr(AssetRegister.Description + ' ' + AssetRegister.Model, '<>'), 1, MaxStrLen(EmployeeItem.Description));
            EmployeeItem."Start Date" := StartDate;
            EmployeeItem."Source Doc. No." := OpeningSourceDocTxt;
            EmployeeItem."Tag No." := AssetRegister."Tag No.";
            EmployeeItem."Employee Name" := EmployeeName;
            if AssetRegister."Physical Count" > 1 then
                EmployeeItem.Quantity := AssetRegister."Physical Count"
            else
                EmployeeItem.Quantity := 1;
            EmployeeItem."Issuing Store" := AssetRegister."Location Code";
            EmployeeItem."Approved By" := CopyStr(UserId(), 1, MaxStrLen(EmployeeItem."Approved By"));
            EmployeeItem.Insert(true);
            EmployeeItem.AllocateItem();
        end;

        AssetRegister."Availability Status" := AssetRegister."Availability Status"::Issued;
        AssetRegister."Issued Date" := StartDate;
        // Replace whatever spelling was typed with the name on the Employee card.
        AssetRegister."Assigned To" := EmployeeName;
        AssetRegister."Return Date" := 0D;
        AssetRegister."Return To" := '';
        AssetRegister.Modify(true);
    end;

    // Every way an employee might have been written in "Assigned To": the full
    // name (first, middle, last), first + last without the middle name, first +
    // middle without the last name, last + first, and the Employee No. itself. A spelling shared by two employees is
    // ambiguous and is never used to link.
    local procedure BuildEmployeeIndex(var NameToEmployee: Dictionary of [Text, Text]; var AmbiguousNames: List of [Text])
    var
        Employee: Record Employee;
        StoreEmployeeNameMgt: Codeunit "Store Employee Name Mgt.";
    begin
        if Employee.FindSet() then
            repeat
                AddKey(NameToEmployee, AmbiguousNames, Employee."No.", Employee."No.");
                AddKey(NameToEmployee, AmbiguousNames, StoreEmployeeNameMgt.FullName(Employee."No."), Employee."No.");
                AddKey(NameToEmployee, AmbiguousNames, Employee."First Name" + ' ' + Employee."Last Name", Employee."No.");
                if Employee."Middle Name" <> '' then
                    AddKey(NameToEmployee, AmbiguousNames, Employee."First Name" + ' ' + Employee."Middle Name", Employee."No.");
                AddKey(NameToEmployee, AmbiguousNames, Employee."Last Name" + ' ' + Employee."First Name", Employee."No.");
            until Employee.Next() = 0;
    end;

    local procedure AddKey(var NameToEmployee: Dictionary of [Text, Text]; var AmbiguousNames: List of [Text]; RawName: Text; EmployeeNo: Code[20])
    var
        NameKey: Text;
    begin
        NameKey := Normalize(RawName);
        if NameKey = '' then
            exit;
        if AmbiguousNames.Contains(NameKey) then
            exit;
        if NameToEmployee.ContainsKey(NameKey) then begin
            if NameToEmployee.Get(NameKey) <> EmployeeNo then begin
                NameToEmployee.Remove(NameKey);
                AmbiguousNames.Add(NameKey);
            end;
            exit;
        end;
        NameToEmployee.Add(NameKey, EmployeeNo);
    end;

    // Case, surrounding spaces and doubled spaces are ignored when comparing names.
    local procedure Normalize(Value: Text): Text
    begin
        Value := UpperCase(DelChr(Value, '<>', ' '));
        while StrPos(Value, '  ') > 0 do
            Value := Value.Replace('  ', ' ');
        exit(Value);
    end;

    var
        OpeningSourceDocTxt: Label 'OPENING', Locked = true;
        ConfirmQst: Label 'Link every asset that has an Assigned To name but is still marked Available to the matching employee? Each one is recorded as issued to that employee, as if it had gone out on a store requisition.';
        ResultMsg: Label '%1 assets linked to employees.\\Not linked:\%2 - Assigned To matches no employee\%3 - Assigned To matches more than one employee\%4 - no Tag Number (generate one first)\\Fix those rows (use the name exactly as on the Employee card, or type the Employee No.) and run this again.', Comment = '%1 = linked, %2 = no match, %3 = ambiguous, %4 = no tag';
}
