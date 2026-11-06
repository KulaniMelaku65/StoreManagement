page 60111 "Store Inventory Register List"
{
    ApplicationArea = All;
    Caption = 'Inventory Register';
    PageType = List;
    SourceTable = "Store Inventory Register";
    UsageCategory = Lists;
    Editable = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Category; Rec.Category)
                {
                    ApplicationArea = All;
                }
                field("Program Code"; Rec."Program Code")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = All;
                }
                field("Total Cost"; Rec."Total Cost")
                {
                    ApplicationArea = All;
                }
                field("Physical Count"; Rec."Physical Count")
                {
                    ApplicationArea = All;
                }
                field(Variance; Rec.Variance)
                {
                    ApplicationArea = All;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field(Remarks; Rec.Remarks)
                {
                    ApplicationArea = All;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field("Last Counted Date"; Rec."Last Counted Date")
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
            action(ImportCsv)
            {
                ApplicationArea = All;
                Caption = 'Import from CSV';
                Image = ImportExcel;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Bulk-load rows from a CSV file, in the order: Category, Program, Description, UoM, Quantity, Unit Cost, Physical Count, Location, Status, Remarks.';

                trigger OnAction()
                var
                    InventoryImport: Codeunit "Store Inv. Register Import";
                begin
                    InventoryImport.ImportFromCsv();
                    CurrPage.Update(false);
                end;
            }
            action(MarkCounted)
            {
                ApplicationArea = All;
                Caption = 'Mark Counted Today';
                Image = CheckList;
                ToolTip = 'Stamp the selected entries as counted today, for a physical count exercise.';

                trigger OnAction()
                var
                    InventoryRegister: Record "Store Inventory Register";
                begin
                    CurrPage.SetSelectionFilter(InventoryRegister);
                    if InventoryRegister.FindSet(true) then
                        repeat
                            InventoryRegister."Last Counted Date" := Today();
                            InventoryRegister.Modify();
                        until InventoryRegister.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
            // No "Create Item" action here - Finance owns creating Item cards. A
            // register row gets its Item No. only by being linked to whatever
            // Finance already created, not by the store keeper creating a new one.
        }
    }

}
