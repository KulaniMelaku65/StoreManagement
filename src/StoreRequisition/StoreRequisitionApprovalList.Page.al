page 60161 "Store Req. Approval List"
{
    Caption = 'Store Requisitions (All Staff)';
    PageType = List;
    SourceTable = "PROC-Store Requistion Header";
    CardPageId = "PROC-Store Req. Header (B)";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    // Fanisi's own requisition list filters to the logged-in user's own documents
    // (User ID = me), so a Store Manager or Store Keeper never sees what staff
    // raised. This list has no such filter: it is for the people who approve and
    // issue. Status is filtered by whatever opens it (tile or menu entry).

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("Request date"; Rec."Request date")
                {
                    ApplicationArea = All;
                }
                field("Required Date"; Rec."Required Date")
                {
                    ApplicationArea = All;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    Caption = 'Created By';
                }
                field("Request Description"; Rec."Request Description")
                {
                    ApplicationArea = All;
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = All;
                }
                field(EmployeeFullName; EmployeeFullName)
                {
                    ApplicationArea = All;
                    Caption = 'Employee Name';
                }
                field("Assigned To"; Rec."Assigned To")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Approved By"; Rec."Approved By")
                {
                    ApplicationArea = All;
                }
                field("Approved Date"; Rec."Approved Date")
                {
                    ApplicationArea = All;
                }
                field("Issuing Store"; Rec."Issuing Store")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ApproveForIssue)
            {
                ApplicationArea = All;
                Caption = 'Approve for Issue';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Enabled = Rec.Status = Rec.Status::Open;
                ToolTip = 'Store Manager only: approve the selected requisition so the store keeper can issue the items. You cannot approve your own request.';

                trigger OnAction()
                var
                    StoreReqApprovalMgt: Codeunit "Store Req. Approval Mgt.";
                begin
                    StoreReqApprovalMgt.ApproveForIssue(Rec);
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
}
