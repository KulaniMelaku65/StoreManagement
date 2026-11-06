page 60109 "Store Manager Role Center"
{
    PageType = RoleCenter;
    Caption = 'Store Manager';

    layout
    {
        area(rolecenter)
        {
            part(Headline; "Store Keeper Headline")
            {
                ApplicationArea = All;
            }
            part(Activities; "Store Keeper Activities")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(sections)
        {
            group(StoreRequisitions)
            {
                Caption = 'Store Requisitions';

                action(RequisitionsAwaitingApproval)
                {
                    Caption = 'Requisitions Awaiting Approval';
                    ToolTip = 'Requisitions raised by staff, waiting for you to click Approve for Issue.';
                    Image = Approve;
                    RunObject = page "Store Req. Approval List";
                    RunPageView = where(Status = filter(Open));
                    ApplicationArea = All;
                }
                action(RequisitionsReadyToIssue)
                {
                    Caption = 'Requisitions Ready to Issue';
                    ToolTip = 'Requisitions you approved, waiting for the store keeper to issue and post.';
                    Image = OrderList;
                    RunObject = page "Store Req. Approval List";
                    RunPageView = where(Status = filter(Released));
                    ApplicationArea = All;
                }
                action(AllStoreRequisitions)
                {
                    Caption = 'All Store Requisitions';
                    ToolTip = 'Every store requisition from all staff, in any status.';
                    Image = List;
                    RunObject = page "Store Req. Approval List";
                    ApplicationArea = All;
                }
                action(IssueReturnHistory)
                {
                    Caption = 'Issue and Return History';
                    ToolTip = 'Everything issued to staff and when it was returned, newest first.';
                    Image = History;
                    RunObject = page "Store Issue Return History";
                    ApplicationArea = All;
                }
                action(EmployeeItems)
                {
                    Caption = 'Items Issued to Staff';
                    ToolTip = 'Items currently allocated to an employee, and where to return them once handed back.';
                    Image = ItemAvailability;
                    RunObject = page "Employee Items";
                    ApplicationArea = All;
                }
            }
            group(RiskManagement)
            {
                Caption = 'Risk Management';

                action(RiskRegister)
                {
                    Caption = 'Risk Register';
                    ToolTip = 'Identified risks tied to company assets - theft, damage, loss, and unauthorized use.';
                    Image = CheckList;
                    RunObject = page "Risk Identification List";
                    ApplicationArea = All;
                }
                action(RiskAnalysis)
                {
                    Caption = 'Risk Analysis';
                    ToolTip = 'Probability and impact scoring for identified risks.';
                    Image = Warning;
                    RunObject = page "Risk Analysis List";
                    ApplicationArea = All;
                }
                action(RiskResponse)
                {
                    Caption = 'Risk Response';
                    ToolTip = 'Existing control measures and management strategy per risk.';
                    Image = Approve;
                    RunObject = page "Risk Response List";
                    ApplicationArea = All;
                }
                action(RiskMonitoring)
                {
                    Caption = 'Risk Monitoring';
                    ToolTip = 'Key risk indicators, review dates, and residual risk for open entries.';
                    Image = History;
                    RunObject = page "Risk Monitoring List";
                    ApplicationArea = All;
                }
                action(PostTreatmentAssessment)
                {
                    Caption = 'Post-Treatment Assessment';
                    ToolTip = 'Re-assessed probability and impact after controls have been applied.';
                    Image = Change;
                    RunObject = page "Post Risk Assessment List";
                    ApplicationArea = All;
                }
            }
            // Assets and Inventory each get their own drop-down; no Items / Fixed
            // Assets lists - the registers are the working records and Finance
            // owns the Item and Fixed Asset cards.
            group(Assets)
            {
                Caption = 'Assets';

                action(AssetRegister)
                {
                    Caption = 'Asset Register';
                    ToolTip = 'Every tagged unit, where it is, and who holds it.';
                    Image = ItemGroup;
                    RunObject = page "Store Asset Register List";
                    ApplicationArea = All;
                }
                action(AssetTransfers)
                {
                    Caption = 'Asset Transfers';
                    ToolTip = 'Transfers of tagged units to another location or employee. Confirm the ones raised by the store keeper.';
                    Image = TransferOrder;
                    RunObject = page "Store Asset Transfer List";
                    ApplicationArea = All;
                }
                action(AssetRegisterSummary)
                {
                    Caption = 'Asset Register Summary';
                    ToolTip = 'Totals by asset class, type, description and model, with available and issued units.';
                    Image = Statistics;
                    RunObject = page "Store Asset Register Summary";
                    ApplicationArea = All;
                }
            }
            group(Inventory)
            {
                Caption = 'Inventory';

                action(InventoryRegister)
                {
                    Caption = 'Inventory Register';
                    ToolTip = 'Consumables and stock items tracked by quantity, with physical count and variance.';
                    Image = Inventory;
                    RunObject = page "Store Inventory Register List";
                    ApplicationArea = All;
                }
                action(InventoryRegisterSummary)
                {
                    Caption = 'Inventory Register Summary';
                    ToolTip = 'One row per item: total quantity, physical count, variance and cost, rolled up from the Inventory Register.';
                    Image = Statistics;
                    RunObject = page "Store Inv. Register Summary";
                    ApplicationArea = All;
                }
                action(PhysInventoryJournal)
                {
                    Caption = 'Physical Inventory Journal';
                    ToolTip = 'Review counted quantities entered by the Store Keeper and post the adjustment.';
                    Image = Journals;
                    RunObject = page "Phys. Inventory Journal";
                    ApplicationArea = All;
                }
            }
            group(Receiving)
            {
                Caption = 'Receiving';

                action(GoodsReceived)
                {
                    Caption = 'Goods Received Notes';
                    ToolTip = 'Stock received into the store against a purchase order.';
                    Image = PostedReceipts;
                    RunObject = page "Custom GRN Header";
                    ApplicationArea = All;
                }
            }
        }
    }
}
