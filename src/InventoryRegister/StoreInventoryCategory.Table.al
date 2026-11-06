table 60147 "Store Inventory Category"
{
    Caption = 'Inventory Category';
    DataClassification = CustomerContent;
    LookupPageId = "Store Inventory Categories";
    DrillDownPageId = "Store Inventory Categories";

    fields
    {
        field(1; Code; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}
