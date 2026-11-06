tableextension 60152 "Custom GRN Lines Ext" extends "Custom GRN Lines"
{
    fields
    {
        // Filled in by the store keeper, one physical unit per line (both Fixed
        // Asset and Item lines are split one-unit-per-line at GRN generation -
        // see Store Asset Register GRN Mgt./Store Inventory Register GRN Mgt.).
        // Once Category is filled in and the GRN is confirmed, this flows
        // straight onto a new Asset Register entry (tagged) or Inventory
        // Register entry, depending on the line's Type.
        field(60100; Category; Code[10])
        {
            Caption = 'Category';
            TableRelation = if (Type = const("Fixed Asset")) "Store Asset Category"
            else
            if (Type = const(Item)) "Store Inventory Category";
        }
        field(60101; "Asset Type"; Code[10])
        {
            Caption = 'Asset Type';
            TableRelation = "Store Asset Type";
        }
        field(60102; Model; Text[100])
        {
            Caption = 'Model';
        }
        field(60103; "Serial No."; Text[50])
        {
            Caption = 'Serial No.';
        }
        field(60104; "Register Entry No."; Integer)
        {
            Caption = 'Asset Register Entry No.';
            Editable = false;
            TableRelation = "Store Asset Register"."Entry No.";
        }
        // Unit Cost plus the line's VAT %, taken from the purchase line when the
        // GRN is created. Equal to Unit Cost when the line carries no VAT.
        field(60106; "Unit Cost Incl. VAT"; Decimal)
        {
            Caption = 'Unit Cost Incl. VAT';
            Editable = false;
            DecimalPlaces = 2 : 5;
        }
        field(60107; "Line Amount Incl. VAT"; Decimal)
        {
            Caption = 'Line Amount Incl. VAT';
            Editable = false;
            DecimalPlaces = 2 : 5;
        }
        // Copied from the Location Code on the Purchase Order / Posted Purchase
        // Invoice line when the GRN is created, and carried onto the Asset or
        // Inventory Register entry when the GRN is confirmed.
        field(60108; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(60105; "Inventory Entry No."; Integer)
        {
            Caption = 'Inventory Register Entry No.';
            Editable = false;
            TableRelation = "Store Inventory Register"."Entry No.";
        }
    }
}
