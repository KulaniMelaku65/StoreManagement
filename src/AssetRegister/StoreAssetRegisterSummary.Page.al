page 60141 "Store Asset Register Summary"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Store Asset Register Summary";
    SourceTableTemporary = true;
    Caption = 'Asset Register Summary';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

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
                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Model; Rec.Model)
                {
                    ApplicationArea = All;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field("Total Physical Count"; Rec."Total Physical Count")
                {
                    ApplicationArea = All;
                }
                field("No. of Tagged Units"; Rec."No. of Tagged Units")
                {
                    ApplicationArea = All;
                    ToolTip = 'How many individual Asset Register rows (tagged or not) make up this total. If this is less than the Total Physical Count, use Split into Tagged Units on the Asset Register to break the remainder into individually tagged rows.';
                }
                field("Available Units"; Rec."Available Units")
                {
                    ApplicationArea = All;
                    ToolTip = 'How many of these tagged units are currently in the store and free to issue.';
                }
                field("Issued Units"; Rec."Issued Units")
                {
                    ApplicationArea = All;
                    ToolTip = 'How many of these tagged units are currently issued to an employee.';
                }
                field("Disposed Units"; Rec."Disposed Units")
                {
                    ApplicationArea = All;
                    ToolTip = 'How many of these tagged units have been disposed.';
                }
                field("Total Cost"; Rec."Total Cost")
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
            action(ShowUnits)
            {
                ApplicationArea = All;
                Caption = 'Show Tagged Units';
                Image = ViewDetails;
                ToolTip = 'Open the individual Asset Register rows that make up this total.';

                trigger OnAction()
                var
                    AssetRegister: Record "Store Asset Register";
                begin
                    AssetRegister.SetRange(Category, Rec.Category);
                    AssetRegister.SetRange("Type", Rec."Type");
                    AssetRegister.SetRange(Description, Rec.Description);
                    AssetRegister.SetRange(Model, Rec.Model);
                    AssetRegister.SetRange("Location Code", Rec."Location Code");
                    Page.Run(Page::"Store Asset Register List", AssetRegister);
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Recalculate the totals below from the current Asset Register.';

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

    local procedure BuildSummary()
    var
        AssetRegister: Record "Store Asset Register";
        EntryNo: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        AssetRegister.SetCurrentKey(Category, "Type", Description, Model, "Location Code");
        if AssetRegister.FindSet() then
            repeat
                FindOrCreateSummaryRow(AssetRegister, EntryNo);
            until AssetRegister.Next() = 0;
        if Rec.FindFirst() then;
    end;

    local procedure FindOrCreateSummaryRow(AssetRegister: Record "Store Asset Register"; var EntryNo: Integer)
    begin
        Rec.SetRange(Category, AssetRegister.Category);
        Rec.SetRange("Type", AssetRegister."Type");
        Rec.SetRange(Description, AssetRegister.Description);
        Rec.SetRange(Model, AssetRegister.Model);
        Rec.SetRange("Location Code", AssetRegister."Location Code");
        if not Rec.FindFirst() then begin
            EntryNo += 1;
            Rec.Init();
            Rec."Entry No." := EntryNo;
            Rec.Category := AssetRegister.Category;
            Rec."Type" := AssetRegister."Type";
            Rec.Description := AssetRegister.Description;
            Rec.Model := AssetRegister.Model;
            Rec."Location Code" := AssetRegister."Location Code";
            Rec.Insert();
        end;
        Rec."Total Physical Count" += AssetRegister."Physical Count";
        Rec."No. of Tagged Units" += 1;
        case AssetRegister."Availability Status" of
            AssetRegister."Availability Status"::Available:
                Rec."Available Units" += 1;
            AssetRegister."Availability Status"::Issued:
                Rec."Issued Units" += 1;
            AssetRegister."Availability Status"::Disposed:
                Rec."Disposed Units" += 1;
        end;
        Rec."Total Cost" += AssetRegister."Total Cost";
        Rec.Modify();
        Rec.Reset();
    end;
}
