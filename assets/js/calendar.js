window.activeDate = new Date()

$(document).ready(function() {
    setCalendar()
})

function setCalendar(d=new Date()) {
    $('#monthLabel').text(d.toLocaleString('default', { month: 'long' }) + ' - ' + d.getFullYear())
    const offset = new Date(d.getFullYear(), d.getMonth(), 1).getDay()
    const days = getDaysInMonth(d)
    const prevDays = getDaysInMonth(new Date(d.getFullYear(), d.getMonth()-1, 1))
    let cells = document.querySelectorAll('.day-cell')
    let nextMonthDayCount = 1;
    for (let i = 0; i < cells.length; ++i) {
        if (i < offset) {
            cells[i].innerHTML = '<span class="text-gray-300 p-1">' + (i + 1 - offset - (-1 * prevDays.length)) + '</span>'
        } else if (i >= days.length+offset) {
            // couldn't figure out how to do this one with math like above and below :/
            cells[i].innerHTML = '<span class="text-gray-300 p-1">' + (nextMonthDayCount++) + '</span>'
        } else {
            cells[i].innerHTML = '<span class="text-gray-500 p-1">' + (i - offset + 1) + '</span>'
        }
    }
}

function nextMonthDate() {
    window.activeDate = new Date(window.activeDate.getFullYear(), window.activeDate.getMonth()+1, window.activeDate.getDay())
    return window.activeDate
}

function prevMonthDate() {
    window.activeDate = new Date(window.activeDate.getFullYear(), window.activeDate.getMonth()-1, window.activeDate.getDay())
    return window.activeDate
}

function getDaysInMonth(src) {
    d = new Date(src.getFullYear(), src.getMonth(), 1)
    let days = []
    while (d.getMonth() === src.getMonth()) {
        days.push(d)
        d.setDate(d.getDate() + 1)
    }
    return days
}