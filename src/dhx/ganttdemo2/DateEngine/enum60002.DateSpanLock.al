// =============================================
// 60002 Enum "Date Span Lock"
// =============================================
enum 60002 "Date Span Lock"
{
    Extensible = false;

    value(0; None) { Caption = 'None'; }
    value(1; LockStart) { Caption = 'Lock Start'; }
    value(2; LockEnd) { Caption = 'Lock End'; }
    value(3; LockBoth) { Caption = 'Lock Both'; }
}
