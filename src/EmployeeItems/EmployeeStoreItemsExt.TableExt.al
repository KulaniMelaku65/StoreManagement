tableextension 60184 "Employee Store Items Ext" extends Employee
{
    // Counts for the Employee Assets API. FlowFields rather than values worked
    // out in the page, so the portal can filter on them
    // (e.g. $filter=holdingCount gt 0 to skip employees who hold nothing).
    fields
    {
        field(60180; "Store Items Held"; Integer)
        {
            Caption = 'Items Held';
            FieldClass = FlowField;
            CalcFormula = count("Employee Items" where("Employee No." = field("No."), Allocated = const(true), Returned = const(false)));
            Editable = false;
        }
        field(60181; "Store Items Total"; Integer)
        {
            Caption = 'Items Ever Issued';
            FieldClass = FlowField;
            CalcFormula = count("Employee Items" where("Employee No." = field("No.")));
            Editable = false;
        }
    }
}
