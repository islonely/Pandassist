$(document).ready(function() {
    $('#studentYear').val(getSchoolYear())

    let selectedStudents = []

    $('.student').on('click', function(evt) {
        evt.stopPropagation()
        $(this).css({background: '#c8daf5ad'})
        selectedStudents += this
    })

    $(window).on('click', function(evt) {
        $('.student').css({background: 'white'})
        selectedStudents = []

        closePopups()
    })
})

function closePopups(ignore=null) {
    let popupIds = ['#newEventPopup', '#newStudentPopup']
    if (ignore != null)
        if (popupIds.indexOf(ignore) >= 0)
            delete popupIds[popupIds.indexOf(ignore)]
    popupIds.forEach(val => {
        if (val !== undefined)
            $(val).fadeOut(60)
    })
}

function createEvent() {
    // TODO: handle event creations
    // should add event to list on dashboard
    // and to database via ajax
}