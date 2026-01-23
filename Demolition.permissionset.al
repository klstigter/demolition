namespace Demolition;

using Microsoft.Projects.Project.Job;

permissionset 50600 Demolition
{
    Assignable = true;
    Permissions = tabledata "Object Selection" = RIMD,
        tabledata "PLanning Cue" = RIMD,
        table "Object Selection" = X,
        table "PLanning Cue" = X,
        codeunit "EventSubs" = X,
        codeunit "Job Planning Line Handler" = X,
        codeunit "Resource DayPilot Handler" = X,
        page "Object Selection" = X,
        page "Job Card - Resource" = X,
        page "Job List - Resource" = X,
        page "Job Planning Line (Project)" = X,
        page "Job Planning Line (Resource)" = X,
        page "Job Task Card - Project" = X,
        page "Job Task Card - Resource" = X,
        page "Job Task List - Project" = X,
        page "Job Task List - Resource" = X,
        page "Planning Role Center" = X,
        page "Project Planning Activities" = X,
        page "Resource Planning Activities" = X;
}