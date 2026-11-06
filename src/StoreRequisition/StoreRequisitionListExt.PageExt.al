pageextension 60113 "Store Requisition List Ext" extends "PROC-Store Requisition"
{
    layout
    {
        addafter("Request Description")
        {
            field("Employee No."; Rec."Employee No.")
            {
                ApplicationArea = All;
            }
            field(EmployeeFullName; EmployeeFullName)
            {
                ApplicationArea = All;
                Caption = 'Employee Name';
                Editable = false;
                ToolTip = 'The employee full name from the Employee card.';
            }
            field("Assigned To"; Rec."Assigned To")
            {
                ApplicationArea = All;
            }
            field("Employee Location Code"; Rec."Employee Location Code")
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
        }
    }

    actions
    {
        // No approval workflow for store requisitions - these either never worked
        // (Approvals/sendApproval/cancellsApproval all depend on a workflow that no
        // longer runs) or would send the request into a queue nobody processes anymore.
        modify(Approvals)
        {
            Visible = false;
        }
        modify(sendApproval)
        {
            Visible = false;
        }
        modify(cancellsApproval)
        {
            Visible = false;
        }
        // Fires only once the base action actually reaches Posted (it stops short of
        // here on error, so nothing downstream runs for a failed or partial post).
        modify("Post Store Requisition")
        {
            Visible = false;
        }

        addafter("Post Store Requisition")
        {
            action(PostStoreRequisitionOwn)
            {
                Caption = 'Post Store Requisition';
                Image = PostOrder;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Category5;
                ApplicationArea = All;
                Enabled = Rec.Status = Rec.Status::Released;
                ToolTip = 'Issue the approved items or assets to the employee. Assets must have their Tag No. selected.';

                trigger OnAction()
                begin
                    StoreRequisitionPostMgt.PostRequisition(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(ReleaseForIssue)
            {
                Caption = 'Approve for Issue';
                Image = Approve;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Category5;
                ApplicationArea = All;
                Enabled = Rec.Status = Rec.Status::Open;
                ToolTip = 'Store Manager only: approve this requisition so the store keeper can issue the items. You cannot approve your own request.';

                trigger OnAction()
                begin
                    StoreReqApprovalMgt.ApproveForIssue(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(ViewEmployeeItems)
            {
                Caption = 'Items Issued to Employee';
                Image = ItemAvailability;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                ToolTip = 'View or return the items this requisition issued to the employee.';
                RunObject = page "Employee Items";
                RunPageLink = "Source Doc. No." = field("No.");
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
        StoreRequisitionPostMgt: Codeunit "Store Requisition Post Mgt.";
        StoreReqApprovalMgt: Codeunit "Store Req. Approval Mgt.";
}
