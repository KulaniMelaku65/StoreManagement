pageextension 60116 "Risk Identification Card Ext" extends "Risk Identification Card"
{
    actions
    {
        // No approval workflow for risk entries - work through Identification, Analysis,
        // Response, Monitoring, and Post-Treatment Assessment directly on this card;
        // nothing downstream is gated on Approval Status.
        modify(SendRequest)
        {
            Visible = false;
        }
        modify(CancelRequest)
        {
            Visible = false;
        }
        modify(Approval)
        {
            Visible = false;
        }
    }
}
