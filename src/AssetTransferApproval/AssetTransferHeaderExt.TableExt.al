tableextension 60102 "Asset Transfer Header Ext" extends "HR Asset Transfer Header"
{
    fields
    {
        field(60100; "Submitted By"; Code[50])
        {
            Caption = 'Submitted By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(60101; "Submitted Date"; Date)
        {
            Caption = 'Submitted Date';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(60102; "Approved By"; Code[50])
        {
            Caption = 'Approved By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(60103; "Approved Date"; Date)
        {
            Caption = 'Approved Date';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(60104; "Rejection Reason"; Text[250])
        {
            Caption = 'Rejection Reason';
            DataClassification = CustomerContent;
        }
    }
}
