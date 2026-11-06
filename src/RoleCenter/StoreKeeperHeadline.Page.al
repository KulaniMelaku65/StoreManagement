page 60166 "Store Keeper Headline"
{
    PageType = HeadlinePart;
    Caption = 'Headline';
    RefreshOnActivate = true;

    // The top of the home page: who is signed in and which store role they are
    // working in, in one line. Used by the Store Keeper and Store Manager home
    // pages. It must stay a single line of text, because a headline with more
    // than one line rotates between them.

    layout
    {
        area(content)
        {
            group(GreetingGroup)
            {
                ShowCaption = false;

                field(GreetingText; GreetingText)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Caption = 'Greeting';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        StoreGreetingMgt: Codeunit "Store Greeting Mgt.";
    begin
        GreetingText := StoreGreetingMgt.GreetingWithRole();
    end;

    var
        GreetingText: Text;
}
