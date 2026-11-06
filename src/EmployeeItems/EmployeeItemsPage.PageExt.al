pageextension 60117 "Employee Items Page Ext" extends "Employee Items"
{
    layout
    {
        addafter("Employee No.")
        {
            field(EmployeeFullName; EmployeeFullName)
            {
                ApplicationArea = All;
                Caption = 'Employee Name';
                Editable = false;
                ToolTip = 'The employee full name from the Employee card.';
            }
        }
        addafter("Item No.")
        {
            field("Source Doc. No."; Rec."Source Doc. No.")
            {
                ApplicationArea = All;
            }
            field("Tag No."; Rec."Tag No.")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        // Fanisi's Return Item refuses to run until an End Date has been typed in,
        // as if every return meant the employee was leaving. An item is often just
        // handed back for another reason, so this replaces it with a Return Item
        // that uses today's date when none is entered.
        modify("Return Item")
        {
            Visible = false;
        }

        addafter("Return Item")
        {
            action(ReturnStoreItem)
            {
                ApplicationArea = All;
                Caption = 'Return Item';
                Image = ReturnRelated;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec.Allocated and not Rec.Returned;
                ToolTip = 'Take this item back from the employee. The return date is today unless an End Date has been entered, and an asset becomes Available again.';

                trigger OnAction()
                var
                    StoreAssetReturnMgt: Codeunit "Store Asset Return Mgt.";
                begin
                    if not Confirm(ReturnQst, false, Rec.Description) then
                        exit;

                    // No End Date typed: the item came back today.
                    if Rec."End Date" = 0D then
                        Rec.Validate("End Date", Today());
                    Rec.ReturnItem();

                    // If this custody row was for a specific tagged unit from the
                    // Asset Register, returning it also frees that tag up as
                    // Available again, rather than leaving it stuck marked Issued.
                    StoreAssetReturnMgt.MarkTagReturned(Rec."Tag No.");

                    Message(ReturnedMsg, Rec.Description);
                    CurrPage.Update(false);
                end;
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
        ReturnQst: Label 'Are you sure you want to return %1?', Comment = '%1 = item description';
        ReturnedMsg: Label '%1 has been returned.', Comment = '%1 = item description';
}
