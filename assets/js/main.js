$(document).ready(function () {
    window.selectedStudents = []

    $('.student').on('click', function (evt) {
        evt.stopPropagation()
        $(this).css({ background: '#c8daf5ad' })
        window.selectedStudents += this
    })

    $(window).on('click', windowClick)
})

function windowClick(evt) {
    $('#profileMenu').fadeOut(60)
    $('#backdrop').fadeOut(60)

    $('.student').css({ background: 'white' })
    window.selectedStudents = []

    closePopups()
}

function closePopups(ignore = null) {
    let popupIds = ['#newEventPopup', '#newStudentPopup', '#addSubjectPopup']
    if (ignore != null)
        if (popupIds.indexOf(ignore) >= 0)
            delete popupIds[popupIds.indexOf(ignore)]
    popupIds.forEach(val => {
        if (val !== undefined)
            $(val).fadeOut(60)
    })
}

function showPopup(qsel, evt) {
    if (qsel === undefined || qsel === null)
        return false

    evt.stopPropagation()
    closePopups()
    $('#backdrop').fadeIn(60)
    $(qsel).fadeIn(60)
}

function showToast(msg) {
    if (msg === undefined) {
        console.warn('Cancelling toast. Provided value is `undefined`.')
        return
    }
    let $toast = $('#toast')
    $toast.find('p').text(msg)
    $toast.css({
        left: '50%',
        marginLeft: (-1 * $toast.width() / 2 - 32) + 'px'
    })
    $toast.addClass('toast')
    setTimeout(function () {
        $toast.removeClass('toast')
    }, 3300)
}

function getSchoolYear() {
    let d = new Date()
    let y = d.getFullYear()
    let m = d.getMonth()
    if (m >= 7 /* August */) {
        return y + '-' + (y + 1)
    } else {
        return (y - 1) + '-' + y
    }
}

async function sleep(ms = 0) {
    return new Promise(resolve => setTimeout(resolve, ms));
}