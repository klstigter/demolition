pageextension 50606 MyExtension extends "User Setup"
{
    layout
    {
        // Add changes to page layout here
        addafter("Allow Posting To")
        {
            field("Planning User ID"; Rec."Planning User ID")
            {
                ApplicationArea = All;

                trigger OnAssistEdit()
                var
                    RestMgt: Codeunit "DDSIA Rest API Mgt.";
                    UserId: Integer;
                    UserName: Text;
                begin
                    UserId := RestMgt.SelectPlanningUser(UserName);
                    if UserId <> 0 then begin
                        Rec."Planning User id" := UserId;
                        Rec."Planning User Name" := UserName;
                    end;
                end;
            }

            field("Planning User Name"; Rec."Planning User Name")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
    //myInt: Integer;
}