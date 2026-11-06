page 60129 "Store Asset Categories"
{
    ApplicationArea = All;
    Caption = 'Asset Categories';
    PageType = List;
    SourceTable = "Store Asset Category";
    UsageCategory = Lists;
    Editable = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
