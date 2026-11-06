page 60108 "Store Keeper Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    SourceTable = "Store Keeper Cue";

    layout
    {
        area(content)
        {
            cuegroup(StoreOperations)
            {
                Caption = 'Store Operations';

                field("Open Store Requisitions"; Rec."Open Store Requisitions")
                {
                    ApplicationArea = All;
                    ToolTip = 'Store requisitions raised by staff and waiting for the Store Manager to approve.';
                    DrillDownPageId = "Store Req. Approval List";
                }
                field("Requisitions Ready to Issue"; Rec."Requisitions Ready to Issue")
                {
                    ApplicationArea = All;
                    ToolTip = 'Store requisitions approved by the Store Manager and ready for the store keeper to issue and post.';
                    DrillDownPageId = "Store Req. Approval List";
                }
                field("Pending Goods Receipts"; Rec."Pending Goods Receipts")
                {
                    ApplicationArea = All;
                    ToolTip = 'Goods received notes that have not been confirmed.';
                }
                field("Open Asset Transfers"; Rec."Open Asset Transfers")
                {
                    ApplicationArea = All;
                    ToolTip = 'Asset transfer requests that have not been confirmed.';
                }
                field("Asset Transfers Ready"; Rec."Asset Transfers Ready")
                {
                    ApplicationArea = All;
                    ToolTip = 'Confirmed asset transfers ready to execute.';
                }
            }
            cuegroup(Purchasing)
            {
                Caption = 'Purchasing';

                field("Approved Purchase Orders"; Rec."Approved Purchase Orders")
                {
                    ApplicationArea = All;
                    ToolTip = 'Released purchase orders - use Generate GRN on one to create its goods received note.';
                    DrillDownPageId = "Purchase Order List";
                }
                field("Purchase Invoices Ready"; Rec."Purchase Invoices Ready")
                {
                    ApplicationArea = All;
                    ToolTip = 'Posted purchase invoices that don''t have a GRN yet - use Create GRN on one to create it.';
                    DrillDownPageId = "Posted Purchase Invoices";
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
