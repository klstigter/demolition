page 50697 "WorkOrderApi Opt"
{
    PageType = API;
    Caption = 'Work Order API Optimization';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'WorkOrder';
    EntitySetName = 'WorkOrders';
    SourceTable = "Work Order";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'System Id';
                }
                field(no_; Rec."Work Order No.")
                {
                    Caption = 'No.';
                }
                field(orderIntakeNo_; Rec."Order Intake No.")
                {
                    Caption = 'Order Intake No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(longDescription; Rec.GetDescription())
                {
                    Caption = 'Long Description';
                }
                field(externalReference; Rec."External Reference")
                {
                    Caption = 'External Reference';
                }
                field(customerNo_; Rec."Customer No.")
                {
                    Caption = 'Customer No.';
                }
                field(projectNo_; Rec."Project No.")
                {
                    Caption = 'Project No.';
                }
                field(projectTaskNo_; Rec."Project Task No.")
                {
                    Caption = 'Project Task No.';
                }
                field(contactNo_; Rec."Contact No.")
                {
                    Caption = 'Contact No.';
                }
                field(sourceType; Rec."Source Type")
                {
                    Caption = 'Source Type';
                }
                field(plannedStartDate; Rec."Planned Start Date")
                {
                    Caption = 'Planned Start Date';
                }
                field(plannedEndDate; Rec."Planned End Date")
                {
                    Caption = 'Planned End Date';
                }
                field(deadlineDate; Rec."Deadline Date")
                {
                    Caption = 'Deadline Date';
                }
                field(placeholderDate; Rec."Placeholder Date")
                {
                    Caption = 'Placeholder Date';
                }
                field(requestedHours; Rec."Requested Hours")
                {
                    Caption = 'Requested Hours';
                }
                field(assignedHours; Rec."Assigned Hours")
                {
                    Caption = 'Assigned Hours';
                }
                field(realizedHours; Rec."Realized Hours")
                {
                    Caption = 'Realized Hours';
                }
                field(closed; Rec.Closed)
                {
                    Caption = 'Closed';
                }
                field(closedDate; Rec."Closed Date")
                {
                    Caption = 'Closed Date';
                }
                field(closedReasonCode; Rec."Closed Reason Code")
                {
                    Caption = 'Closed Reason Code';
                }
                field(createdDateTime; Rec."Created DateTime")
                {
                    Caption = 'Created DateTime';
                }
                field(createdBy; Rec."Created By")
                {
                    Caption = 'Created By';
                }
                field(lastModifiedDateTime; Rec."Last Modified DateTime")
                {
                    Caption = 'Last Modified DateTime';
                }
                field(lastModifiedBy; Rec."Last Modified By")
                {
                    Caption = 'Last Modified By';
                }
                field(noSeries; Rec."No. Series")
                {
                    Caption = 'No. Series';
                }
            }
        }
    }
}
