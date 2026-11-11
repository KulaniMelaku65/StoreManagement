table 60178 "Store Assignee Match"
{
    // Worksheet for the go-live take-on: one row per distinct "Assigned To" text
    // on the Asset Register that did not match an employee exactly, with the
    // closest employee the system could find. Someone checks each suggestion
    // (or picks the right employee) before anything is linked.
    Caption = 'Assigned To Name Match';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
        }
        field(10; "Assigned To"; Text[100])
        {
            Caption = 'Assigned To (as typed)';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(11; "Asset Count"; Integer)
        {
            Caption = 'Assets';
            Editable = false;
        }
        field(20; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            var
                StoreEmployeeNameMgt: Codeunit "Store Employee Name Mgt.";
            begin
                "Employee Name" := StoreEmployeeNameMgt.FullName("Employee No.");
                if "Employee No." = '' then begin
                    Accepted := false;
                    exit;
                end;
                if "Employee No." <> xRec."Employee No." then begin
                    "Match Score" := 100;
                    "Match Basis" := ChosenByUserTxt;
                end;
                Accepted := true;
            end;
        }
        field(21; "Employee Name"; Text[100])
        {
            Caption = 'Employee Name (on card)';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(30; "Match Score"; Integer)
        {
            Caption = 'Match %';
            Editable = false;
        }
        field(31; "Match Basis"; Text[250])
        {
            Caption = 'Why';
            Editable = false;
        }
        field(40; "Runner-up"; Text[150])
        {
            Caption = 'Next Closest';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(50; Accepted; Boolean)
        {
            Caption = 'Accepted';

            trigger OnValidate()
            begin
                if Accepted then
                    TestField("Employee No.");
            end;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Score; "Match Score")
        {
        }
    }

    var
        ChosenByUserTxt: Label 'Chosen by you';
}
