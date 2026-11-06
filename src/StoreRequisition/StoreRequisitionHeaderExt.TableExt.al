tableextension 60111 "Store Requisition Header Ext" extends "PROC-Store Requistion Header"
{
    fields
    {
        field(60100; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = Employee;

            trigger OnValidate()
            var
                Employee: Record Employee;
            begin
                if "Employee No." = '' then begin
                    "Employee Name" := '';
                    exit;
                end;
                Employee.Get("Employee No.");
                "Employee Name" := CopyStr(StoreEmployeeNameMgt.FullName("Employee No."), 1, MaxStrLen("Employee Name"));
                // Default only - stays editable so the item can be handed to someone
                // other than the person who requested it.
                "Assigned To" := "Employee Name";
            end;
        }
        field(60101; "Employee Name"; Text[100])
        {
            Caption = 'Employee Name';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(60102; "Assigned To"; Text[100])
        {
            Caption = 'Assigned To';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(60104; "Approved By"; Code[50])
        {
            Caption = 'Approved By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(60105; "Approved Date"; Date)
        {
            Caption = 'Approved Date';
            Editable = false;
        }
        field(60103; "Employee Location Code"; Code[10])
        {
            Caption = 'Employee Location';
            DataClassification = CustomerContent;
            TableRelation = Location;
        }
    }

    var
        StoreEmployeeNameMgt: Codeunit "Store Employee Name Mgt.";
}
