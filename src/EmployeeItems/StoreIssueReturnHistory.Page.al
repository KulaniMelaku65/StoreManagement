page 60165 "Store Issue Return History"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Employee Items";
    SourceTableView = sorting("Date Allocated") order(descending) where(Allocated = const(true));
    Caption = 'Issue and Return History';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    // The full record of what was issued to whom and when it came back: every
    // custody row ever created, returned or not. It is read-only - issuing and
    // returning happen from the requisition and from Items Issued to Staff.

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = All;
                }
                field(EmployeeFullName; EmployeeFullName)
                {
                    ApplicationArea = All;
                    Caption = 'Employee Name';
                }
                field("Item Type"; Rec."Item Type")
                {
                    ApplicationArea = All;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field("Tag No."; Rec."Tag No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field("Issuing Store"; Rec."Issuing Store")
                {
                    ApplicationArea = All;
                }
                field("Source Doc. No."; Rec."Source Doc. No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'The store requisition this was issued against.';
                }
                field("Approved By"; Rec."Approved By")
                {
                    ApplicationArea = All;
                }
                field("Allocated By"; Rec."Allocated By")
                {
                    ApplicationArea = All;
                    Caption = 'Issued By';
                }
                field("Date Allocated"; Rec."Date Allocated")
                {
                    ApplicationArea = All;
                    Caption = 'Date Issued';
                }
                field(Returned; Rec.Returned)
                {
                    ApplicationArea = All;
                }
                field("Date Returned"; Rec."Date Returned")
                {
                    ApplicationArea = All;
                }
                field("Return Captured By"; Rec."Return Captured By")
                {
                    ApplicationArea = All;
                    Caption = 'Returned To';
                    ToolTip = 'The store keeper who took the item back.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        EmployeeFullName := StoreEmployeeNameMgt.FullName(Rec."Employee No.");
    end;

    var
        EmployeeFullName: Text[100];
        StoreEmployeeNameMgt: Codeunit "Store Employee Name Mgt.";
}
