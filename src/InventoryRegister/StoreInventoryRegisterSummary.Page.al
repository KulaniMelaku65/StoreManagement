page 60164 "Store Inv. Register Summary"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Store Inv. Register Summary";
    SourceTableTemporary = true;
    Caption = 'Inventory Register Summary';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    // One row per item (same Category, Description, Unit of Measurement, Location
    // and Item No.). A GRN adds one register row per unit received, so the
    // Inventory Register itself can run to hundreds of rows for a handful of
    // items - this rolls them up to what the store actually holds.

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Category; Rec.Category)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field("Total Quantity"; Rec."Total Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'What the system says the store should hold (book quantity).';
                }
                field("Total Physical Count"; Rec."Total Physical Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'What was counted on the shelf.';
                }
                field("Total Variance"; Rec."Total Variance")
                {
                    ApplicationArea = All;
                    StyleExpr = VarianceStyle;
                    ToolTip = 'Physical Count minus Quantity. Anything other than 0 needs an explanation.';
                }
                field("Average Unit Cost"; Rec."Average Unit Cost")
                {
                    ApplicationArea = All;
                }
                field("Total Cost"; Rec."Total Cost")
                {
                    ApplicationArea = All;
                }
                field("No. of Register Rows"; Rec."No. of Register Rows")
                {
                    ApplicationArea = All;
                    ToolTip = 'How many Inventory Register rows make up this total.';
                }
                field("Last Counted Date"; Rec."Last Counted Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'The most recent count date among the rows that make up this total.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowRows)
            {
                ApplicationArea = All;
                Caption = 'Show Register Rows';
                Image = ViewDetails;
                ToolTip = 'Open the individual Inventory Register rows that make up this total.';

                trigger OnAction()
                var
                    InventoryRegister: Record "Store Inventory Register";
                begin
                    InventoryRegister.SetRange(Category, Rec.Category);
                    InventoryRegister.SetRange(Description, Rec.Description);
                    InventoryRegister.SetRange("Unit of Measure Code", Rec."Unit of Measure Code");
                    InventoryRegister.SetRange("Location Code", Rec."Location Code");
                    InventoryRegister.SetRange("Item No.", Rec."Item No.");
                    Page.Run(Page::"Store Inventory Register List", InventoryRegister);
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Recalculate the totals from the current Inventory Register.';

                trigger OnAction()
                begin
                    BuildSummary();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        BuildSummary();
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec."Total Variance" <> 0 then
            VarianceStyle := 'Attention'
        else
            VarianceStyle := 'Standard';
    end;

    local procedure BuildSummary()
    var
        InventoryRegister: Record "Store Inventory Register";
        EntryNo: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        InventoryRegister.SetCurrentKey(Category, "Location Code");
        if InventoryRegister.FindSet() then
            repeat
                AddToSummary(InventoryRegister, EntryNo);
            until InventoryRegister.Next() = 0;
        Rec.Reset();
        if Rec.FindSet(true) then
            repeat
                if Rec."Total Physical Count" <> 0 then
                    Rec."Average Unit Cost" := Round(Rec."Total Cost" / Rec."Total Physical Count", 0.01)
                else
                    if Rec."Total Quantity" <> 0 then
                        Rec."Average Unit Cost" := Round(Rec."Total Cost" / Rec."Total Quantity", 0.01);
                Rec.Modify();
            until Rec.Next() = 0;
        if Rec.FindFirst() then;
    end;

    local procedure AddToSummary(InventoryRegister: Record "Store Inventory Register"; var EntryNo: Integer)
    begin
        Rec.SetRange(Category, InventoryRegister.Category);
        Rec.SetRange(Description, InventoryRegister.Description);
        Rec.SetRange("Unit of Measure Code", InventoryRegister."Unit of Measure Code");
        Rec.SetRange("Location Code", InventoryRegister."Location Code");
        Rec.SetRange("Item No.", InventoryRegister."Item No.");
        if not Rec.FindFirst() then begin
            EntryNo += 1;
            Rec.Init();
            Rec."Entry No." := EntryNo;
            Rec.Category := InventoryRegister.Category;
            Rec.Description := InventoryRegister.Description;
            Rec."Unit of Measure Code" := InventoryRegister."Unit of Measure Code";
            Rec."Location Code" := InventoryRegister."Location Code";
            Rec."Item No." := InventoryRegister."Item No.";
            Rec.Insert();
        end;
        Rec."Total Quantity" += InventoryRegister.Quantity;
        Rec."Total Physical Count" += InventoryRegister."Physical Count";
        Rec."Total Variance" += InventoryRegister.Variance;
        Rec."Total Cost" += InventoryRegister."Total Cost";
        Rec."No. of Register Rows" += 1;
        if InventoryRegister."Last Counted Date" > Rec."Last Counted Date" then
            Rec."Last Counted Date" := InventoryRegister."Last Counted Date";
        Rec.Modify();
        Rec.Reset();
    end;

    var
        VarianceStyle: Text;
}
