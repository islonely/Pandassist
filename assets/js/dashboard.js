$(document).ready(function() {
    let selectedStudents = []

    $('.student').on('click', function(evt) {
        evt.stopPropagation()
        $(this).css({background: '#c8daf5ad'})
        selectedStudents += this
    })

    $(window).on('click', function(evt) {
        $('.student').css({background: 'white'})
        selectedStudents = []

        $('#newEventPopup').fadeOut(60)
    })
})

function createEvent() {
    // TODO: handle event creations
    // should add event to list on dashboard
    // and to database via ajax
}