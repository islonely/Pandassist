(function() {
    let selectedStudents = []
    
    $('.student').on('click', function(evt) {
        evt.stopPropagation()
        $(this).css({background: '#c8daf5ad'})
        selectedStudents += this
    })

    $(window).on('click', function(evt) {
        $('.student').css({background: 'white'})
        selectedStudents = []
    })
}())