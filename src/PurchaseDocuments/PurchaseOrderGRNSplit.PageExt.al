pageextension 60154 "Purchase Order GRN Split Ext" extends "Purchase Order"
{
    actions
    {
        // Fanisi's own Generate GRN is a compiled app we can't fix, and it fails
        // with "The type NavOption is unknown." Hide it and offer our own instead
        // (same place, Print/Send), which builds the same GRN and splits the lines.
        modify("Generate GRN")
        {
            Visible = false;
        }

        addafter("Generate GRN")
        {
            action(CreateStoreGRN)
            {
                Caption = 'Create GRN';
                Image = ReceiptLines;
                ApplicationArea = All;
                // Same promoted category the hidden Fanisi button used (Print/Send tab).
                Promoted = true;
                PromotedCategory = Category10;
                PromotedIsBig = true;
                Enabled = (Rec.Status = Rec.Status::Released) and (not Rec."GRN Generated");
                ToolTip = 'Create the goods received note for this released order. Fixed Asset and Item lines with more than one unit are split into one line per unit.';

                trigger OnAction()
                var
                    StorePOGRNMgt: Codeunit "Store PO GRN Mgt.";
                begin
                    StorePOGRNMgt.GenerateGRNFromOrder(Rec);
                end;
            }
        }
    }
}
