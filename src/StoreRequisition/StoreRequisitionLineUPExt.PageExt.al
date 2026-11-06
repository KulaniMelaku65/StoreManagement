pageextension 60146 "Store Requisition Line UP Ext" extends "PROC-Store Requisition Line UP"
{
    layout
    {
        // One column for both kinds of pick, decided by the line's Type:
        //   Type = Minor Asset -> pick a Tag No. from the Asset Register
        //   Type = Item        -> pick an entry from the Inventory Register
        // Choosing one sets the rest of the line (Fixed Asset or Item, description,
        // store, unit of measure, unit cost) from that register row. The real
        // fields (Tag No. / Inventory Register Entry) live on the line; this
        // column just shows and edits whichever one applies.
        // Fanisi's own Qty in store sums the standard Item ledger, which is zero
        // for assets and for stock that only lives on the register. Show the
        // register's figure instead, in the same place.
        modify("Qty in store")
        {
            Visible = false;
        }
        addafter("Quantity Issued")
        {
            field(QtyInStoreRegister; QtyInStoreRegister)
            {
                ApplicationArea = All;
                Caption = 'Qty in store';
                Editable = false;
                DecimalPlaces = 0 : 5;
                ToolTip = 'What the Asset Register (1 if the tag is available) or the Inventory Register holds for this line.';
            }
        }
        addafter(Type)
        {
            field(RegisterPick; RegisterPick)
            {
                ApplicationArea = All;
                Caption = 'Tag No. / Register Entry';
                ToolTip = 'Set the Type first. Asset: pick the Tag No. of the unit from the Asset Register (only available units are listed). Item: pick the entry from the Inventory Register. The rest of the line fills in from the register.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    exit(LookupRegister(Text));
                end;

                trigger OnValidate()
                begin
                    ApplyRegisterPick();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RegisterPick := CurrentPick();
        QtyInStoreRegister := Rec.RegisterQtyInStore();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        RegisterPick := '';
    end;

    local procedure CurrentPick(): Text
    begin
        case Rec.Type of
            Rec.Type::"Minor Asset":
                exit(Rec."Tag No.");
            Rec.Type::Item:
                if Rec."Stock Entry No." <> 0 then
                    exit(Format(Rec."Stock Entry No."));
        end;
        exit('');
    end;

    local procedure LookupRegister(var PickedText: Text): Boolean
    var
        AssetRegister: Record "Store Asset Register";
        InventoryRegister: Record "Store Inventory Register";
        AssetRegisterList: Page "Store Asset Lookup";
        InventoryRegisterList: Page "Store Inventory Lookup";
    begin
        case Rec.Type of
            Rec.Type::"Minor Asset":
                begin
                    AssetRegister.SetRange("Availability Status", AssetRegister."Availability Status"::Available);
                    AssetRegisterList.SetTableView(AssetRegister);
                    AssetRegisterList.LookupMode(true);
                    if AssetRegisterList.RunModal() = Action::LookupOK then begin
                        AssetRegisterList.GetRecord(AssetRegister);
                        PickedText := AssetRegister."Tag No.";
                        exit(true);
                    end;
                end;
            Rec.Type::Item:
                begin
                    // Only rows linked to an Item card, and that still have stock.
                    InventoryRegister.SetFilter("Item No.", '<>%1', '');
                    InventoryRegister.SetFilter(Quantity, '>0');
                    InventoryRegisterList.SetTableView(InventoryRegister);
                    InventoryRegisterList.LookupMode(true);
                    if InventoryRegisterList.RunModal() = Action::LookupOK then begin
                        InventoryRegisterList.GetRecord(InventoryRegister);
                        PickedText := Format(InventoryRegister."Entry No.");
                        exit(true);
                    end;
                end;
            else
                Error(ChooseTypeErr);
        end;
        exit(false);
    end;

    local procedure ApplyRegisterPick()
    var
        EntryNo: Integer;
    begin
        case Rec.Type of
            Rec.Type::"Minor Asset":
                Rec.Validate("Tag No.", CopyStr(RegisterPick, 1, MaxStrLen(Rec."Tag No.")));
            Rec.Type::Item:
                if RegisterPick = '' then
                    Rec.Validate("Stock Entry No.", 0)
                else begin
                    if not Evaluate(EntryNo, RegisterPick) then
                        Error(EntryNotNumberErr);
                    Rec.Validate("Stock Entry No.", EntryNo);
                end;
            else
                if RegisterPick <> '' then
                    Error(ChooseTypeErr);
        end;
        RegisterPick := CurrentPick();
    end;

    var
        RegisterPick: Text[30];
        QtyInStoreRegister: Decimal;
        ChooseTypeErr: Label 'Set the Type of this line first: Item for stock, Minor Asset for an asset.';
        EntryNotNumberErr: Label 'The Inventory Register entry is a number. Use the lookup to pick it.';
}
