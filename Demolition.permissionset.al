namespace Demolition;

using Microsoft.Projects.Project.Job;

permissionset 50600 Demolition
{
    Assignable = true;
    Permissions = tabledata "DDSIA Incoming Check"=RIMD,
        tabledata "DDSIA Object Selection"=RIMD,
        tabledata "DDSIA PLanning Cue"=RIMD,
        tabledata "Planning Integration Setup"=RIMD,
        tabledata "Request Header"=RIMD,
        tabledata "Request Line"=RIMD,
        table "DDSIA Incoming Check"=X,
        table "DDSIA Object Selection"=X,
        table "DDSIA PLanning Cue"=X,
        table "Planning Integration Setup"=X,
        table "Request Header"=X,
        table "Request Line"=X,
        codeunit "DDSIA Rest API Mgt."=X,
        codeunit DDSIAEventSubs=X,
        codeunit "Job Planning Line Handler"=X,
        codeunit "Resource DayPilot Handler"=X,
        page "DDSIA Incoming Check"=X,
        page "DDSIA Object Selection"=X,
        page DDSIAJobPlanningLine=X,
        page DDSIAJobPlanningLineBor=X,
        page "Job Card - Resource"=X,
        page "Job List - Resource"=X,
        page "Job Planning Line (Project)"=X,
        page "Job Planning Line (Resource)"=X,
        page "Job Task Card - Project"=X,
        page "Job Task Card - Resource"=X,
        page "Job Task List - Project"=X,
        page "Job Task List - Resource"=X,
        page "Planning Integration Setup"=X,
        page "Planning Role Center"=X,
        page "Project Planning Activities"=X,
        page "Resource Planning Activities"=X,
        page "Resource Selection"=X,
        page "Resources Board"=X,
        page "Schedule Board"=X;
}