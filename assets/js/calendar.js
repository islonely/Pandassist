$(document).ready(function() {
    const d = new Date()
    const offset = new Date(d.getFullYear(), d.getMonth(), 1).getDay()
    const days = getDaysInMonth(d)
    const prevDays = getDaysInMonth(new Date(d.getFullYear(), d.getMonth()-1, 1))
    let cells = document.querySelectorAll('.day-cell')
    for (let i = 0; i < cells.length; ++i) {
        if (i < offset) {
            cells[i].innerHTML = '<span class="text-gray-300 p-1">' + (i + 1 - offset - (-1 * prevDays.length)) + '</span>'
        } else if (i >= days.length+offset) {
            cells[i].innerHTML = '<span class="text-gray-300 p-1">' + (i + 1 - days.length) + '</span>'
        } else {
            cells[i].innerHTML = '<span class="text-gray-500 p-1">' + (i - offset + 1) + '</span>'
        }
    }
})

function getDaysInMonth(src) {
    d = new Date(src.getFullYear(), src.getMonth(), 1)
    let days = []
    while (d.getMonth() === src.getMonth()) {
        days.push(d)
        d.setDate(d.getDate() + 1)
    }
    return days
}