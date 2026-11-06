pageextension 60115 "Custom GRN Card Ext" extends "Custom GRN Card"
{
    actions
    {
        // No approval workflow for GRNs - "Approval Request"/"Cancel Request"/
        // "Approvals" all depend on a workflow that no longer runs.
        modify("Approval Request")
        {
            Visible = false;
        }
        modify("Cancel Request")
        {
            Visible = false;
        }
        modify("Approvals")
        {
            Visible = false;
        }

        addafter("Approvals")
        {
            action(ConfirmGRN)
            {
                Caption = 'Confirm GRN';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                Enabled = Rec.Status = Rec.Status::Pending;
                ToolTip = 'Confirm this goods received note is correct. There is no separate approval step.';

                trigger OnAction()
                var
                    StoreAssetRegisterGRNMgt: Codeunit "Store Asset Register GRN Mgt.";
                    StoreInvRegisterGRNMgt: Codeunit "Store Inv. Register GRN Mgt.";
                begin
                    Rec.Validate(Status, Rec.Status::Approved);
                    Rec.Modify(true);
                    // Any Fixed Asset line on this GRN gets its own Asset Register
                    // entry here, carrying the quantity and already linked back to
                    // the Fixed Asset No. Finance created for it.
                    StoreAssetRegisterGRNMgt.CreateRegisterEntriesFromGRN(Rec);
                    // Same for Item lines, but onto the Inventory Register instead.
                    StoreInvRegisterGRNMgt.CreateInventoryEntriesFromGRN(Rec);
                end;
            }
        }
    }
}
