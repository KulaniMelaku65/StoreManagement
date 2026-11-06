table 60169 "Store Asset Transfer"
{
    Caption = 'Asset Transfer';
    DataClassification = CustomerContent;
    LookupPageId = "Store Asset Transfer List";
    DrillDownPageId = "Store Asset Transfer List";

    // A transfer of one tagged unit from the Asset Register: to another store
    // location, to another employee, or both. It replaces Fanisi's Asset Transfer,
    // which only works on Fixed Asset cards and never touches the Asset Register
    // or the custody records.

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        field(2; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(3; "Tag No."; Code[30])
        {
            Caption = 'Tag No.';
            // No TableRelation: Tag Number is not the primary key of the Asset
            // Register, and Business Central refuses a built-in link to a non-key
            // field when it validates or looks it up. The checks are done in code.

            trigger OnValidate()
            var
                AssetRegister: Record "Store Asset Register";
            begin
                if "Tag No." = '' then
                    exit;
                AssetRegister.SetRange("Tag No.", "Tag No.");
                if not AssetRegister.FindFirst() then
                    Error(TagNotFoundErr, "Tag No.");
                if AssetRegister."Availability Status" = AssetRegister."Availability Status"::Disposed then
                    Error(DisposedErr, "Tag No.");
                if AssetRegister."Disposal Status" = AssetRegister."Disposal Status"::PendingApproval then
                    Error(DisposalPendingErr, "Tag No.");
                Description := AssetRegister.Description;
                Model := AssetRegister.Model;
                "Fixed Asset No." := AssetRegister."Fixed Asset No.";
                "From Location Code" := AssetRegister."Location Code";
                "From Holder" := AssetRegister."Assigned To";
            end;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(5; Model; Text[100])
        {
            Caption = 'Model';
            Editable = false;
        }
        field(6; "Fixed Asset No."; Code[20])
        {
            Caption = 'Fixed Asset No.';
            Editable = false;
        }
        field(10; "From Location Code"; Code[10])
        {
            Caption = 'From Location';
            Editable = false;
        }
        field(11; "From Holder"; Text[100])
        {
            Caption = 'Currently With';
            Editable = false;
        }
        field(20; "To Location Code"; Code[10])
        {
            Caption = 'To Location';
            TableRelation = Location;
        }
        field(21; "To Zone Code"; Code[20])
        {
            Caption = 'To Zone';
        }
        field(22; "To Shelf No."; Text[20])
        {
            Caption = 'To Shelf #';
        }
        field(23; "To Employee No."; Code[20])
        {
            Caption = 'To Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            var
                Employee: Record Employee;
            begin
                if "To Employee No." = '' then begin
                    "To Employee Name" := '';
                    exit;
                end;
                Employee.Get("To Employee No.");
                "To Employee Name" := CopyStr(StoreEmployeeNameMgt.FullName("To Employee No."), 1, MaxStrLen("To Employee Name"));
            end;
        }
        field(24; "To Employee Name"; Text[100])
        {
            Caption = 'To Employee Name';
            Editable = false;
        }
        field(30; Reason; Text[100])
        {
            Caption = 'Reason for Transfer';
        }
        field(31; "Expected Back"; Boolean)
        {
            Caption = 'Expected Back';
        }
        field(40; Status; Enum "Store Asset Transfer Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(41; "Created By"; Code[50])
        {
            Caption = 'Created By';
            Editable = false;
        }
        field(42; "Confirmed By"; Code[50])
        {
            Caption = 'Confirmed By';
            Editable = false;
        }
        field(43; "Confirmed Date"; Date)
        {
            Caption = 'Confirmed Date';
            Editable = false;
        }
        field(44; "Transferred By"; Code[50])
        {
            Caption = 'Transferred By';
            Editable = false;
        }
        field(45; "Transferred Date"; Date)
        {
            Caption = 'Transferred Date';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if "No." = '' then
            "No." := NextNo();
        if "Document Date" = 0D then
            "Document Date" := Today();
        "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));
    end;

    trigger OnDelete()
    begin
        if Status = Status::Transferred then
            Error(CannotDeleteErr);
    end;

    local procedure NextNo(): Code[20]
    var
        LastTransfer: Record "Store Asset Transfer";
        LastNumber: Integer;
    begin
        if LastTransfer.FindLast() then
            if Evaluate(LastNumber, CopyStr(LastTransfer."No.", 4)) then;
        exit(CopyStr('AST' + PadStr('', 5 - StrLen(Format(LastNumber + 1)), '0') + Format(LastNumber + 1), 1, 20));
    end;

    var
        StoreEmployeeNameMgt: Codeunit "Store Employee Name Mgt.";
        TagNotFoundErr: Label 'Tag No. %1 was not found on the Asset Register.', Comment = '%1 = tag number';
        DisposedErr: Label 'Tag No. %1 has been disposed and cannot be transferred.', Comment = '%1 = tag number';
        DisposalPendingErr: Label 'Tag No. %1 has a disposal waiting for approval, so it cannot be transferred.', Comment = '%1 = tag number';
        CannotDeleteErr: Label 'A transfer that has been carried out cannot be deleted.';
}
