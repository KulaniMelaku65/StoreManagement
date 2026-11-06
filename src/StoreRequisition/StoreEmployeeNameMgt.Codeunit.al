codeunit 60174 "Store Employee Name Mgt."
{
    // The employee's full name as it is on the Employee card: first, middle and
    // last name. Lives in its own codeunit so the pages that show a name don't
    // each need permission to read the Employee table.
    Permissions = tabledata Employee = R;

    procedure FullName(EmployeeNo: Code[20]): Text[100]
    var
        Employee: Record Employee;
        Result: Text;
    begin
        if EmployeeNo = '' then
            exit('');
        if not Employee.Get(EmployeeNo) then
            exit('');
        Result := Employee."First Name";
        if Employee."Middle Name" <> '' then
            Result := Result + ' ' + Employee."Middle Name";
        if Employee."Last Name" <> '' then
            Result := Result + ' ' + Employee."Last Name";
        exit(CopyStr(DelChr(Result, '<>'), 1, 100));
    end;
}
