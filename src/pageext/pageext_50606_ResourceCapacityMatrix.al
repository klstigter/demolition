pageextension 50606 "ResourceCapacityMatrix opt" extends "Resource Capacity Matrix"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        modify("&Set Capacity")
        {
            Visible = false;
        }
        addafter("&Set Capacity")
        {
            action("Set Capacity Opt")
            {
                ApplicationArea = Jobs;
                Caption = '&Set Capacity';
                RunObject = Page "Resource Capacity Settings Opt";
                RunPageLink = "No." = field("No.");
                ToolTip = 'Change the capacity of the resource, such as a technician.';
            }
            action("Day Tasks (Visual)")
            {
                ApplicationArea = Jobs;
                Caption = 'Day Tasks (Visual)';

                trigger OnAction()
                var
                    ResScheduler: page "DHX Resource Scheduler";
                begin
                    ResScheduler.SetResourceFilter(Rec."No.");
                    ResScheduler.RunModal();
                end;
            }
        }
    }

    var

    procedure ResourceFilter(pResFilter: Text)
    begin
        if pResFilter <> '' then begin
            Rec.Setfilter("No.", pResFilter);
            CurrPage.Update();
        end;
    end;
}

// pageextension 50606 "ResourceCapacitySettings opt" extends "Resource Capacity Settings"
// {
//     layout
//     {
//         // Add changes to page layout here
//     }

//     actions
//     {
//         // Add changes to page actions here
//         modify(UpdateCapacity)
//         {
//             Visible = false;
//         }
//         addbefore(UpdateCapacity)
//         {
//             action(UpdateCapacityOpt)
//             {
//                 ApplicationArea = Basic, Suite;
//                 Caption = 'Update &Capacity';
//                 Image = Approve;
//                 ToolTip = 'Update the capacity based on the changes you have made in the window.';
//                 trigger OnAction()
//                 begin
//                     Message('Under Development');
//                 end;
//             }
//         }
//         addafter(UpdateCapacity_Promoted)
//         {
//             actionref(UpdateCapacity_Promoted_Opt; UpdateCapacityOpt)
//             {
//             }
//         }
//     }

//     var
// }