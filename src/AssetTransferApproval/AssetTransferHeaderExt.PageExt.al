pageextension 60104 "Asset Transfer Header Ext" extends "Hr Asset  Transfer Header"
{
    layout
    {
        addafter(Status)
        {
            field("Submitted By"; Rec."Submitted By")
            {
                ApplicationArea = All;
            }
            field("Submitted Date"; Rec."Submitted Date")
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
        // No approval workflow: the base "Send/Cancel Approval Request" actions ship
        // empty anyway (never wired up), and Rejection Reason no longer applies since
        // there's no separate approver to reject it.
        modify("Send Approval Request")
        {
            Visible = false;
        }
        modify("Cancel Approval Request")
        {
            Visible = false;
        }
        // The base "Transfer" action had no status check at all - anyone could execute a
        // transfer before it was confirmed. Gate it so it only runs once Approved.
        modify(Transfer)
        {
            Enabled = Rec.Status = Rec.Status::Approved;
        }

        addafter("Send Approval Request")
        {
            action(ConfirmTransfer)
            {
                Caption = 'Confirm Transfer';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ApplicationArea = All;
                Enabled = Rec.Status = Rec.Status::Open;
                ToolTip = 'Confirm this transfer is correct and ready to execute. There is no separate approval step.';

                trigger OnAction()
                begin
                    AssetTransferApprovalMgt.Confirm(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        AssetTransferApprovalMgt: Codeunit "Asset Transfer Approval Mgt.";
}
