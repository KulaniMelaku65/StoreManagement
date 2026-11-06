tableextension 60112 "Employee Items Ext" extends "Employee Items"
{
    fields
    {
        field(60100; "Source Doc. No."; Code[20])
        {
            Caption = 'Source Document No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(60101; "Tag No."; Code[30])
        {
            Caption = 'Tag No.';
            DataClassification = CustomerContent;
            Editable = false;
            // No TableRelation: Tag Number is not the primary key of the Asset
            // Register, and Business Central refuses a built-in link to a non-key
            // field when it validates or looks it up. The checks are done in code.
        }
        // Kept for the issue/return history, so the record shows who, what, how
        // many, from where, and who approved - not just that an item was allocated.
        field(60102; "Employee Name"; Text[100])
        {
            Caption = 'Employee Name';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(60103; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
            Editable = false;
            DecimalPlaces = 0 : 5;
        }
        field(60104; "Issuing Store"; Code[10])
        {
            Caption = 'Issued From';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(60105; "Approved By"; Code[50])
        {
            Caption = 'Approved By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
    }

    keys
    {
        // For the history page, newest first.
        key(DateAllocatedKey; "Date Allocated")
        {
        }
    }
}
