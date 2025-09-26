function getWeekStart(date) {
    const d = new Date(date);
    const day = d.getDay(); // Sunday=0, Monday=1, ..., Saturday=6
    const diffToMonday = (day + 6) % 7; // Number of days since Monday
    d.setDate(d.getDate() - diffToMonday);
    d.setHours(0,0,0,0); // Optional: reset to midnight
    
    // Format yyyy-mm-dd
    const yyyy = d.getFullYear();
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
}