function showToast(msg) {
    if (msg === undefined) {
        console.warn('Cancelling toast. Provided value is `undefined`.')
        return
    }
    let $toast = $('#toast')
    $toast.find('p').text(msg)
    $toast.css({
        left: '50%',
        marginLeft: (-1 * $toast.width()/2 - 32) + 'px'
    })
    $toast.addClass('toast')
    setTimeout(function(){
        $toast.removeClass('toast')
    }, 3300)
}

function getSchoolYear() {
    let d = new Date()
    let y = d.getFullYear()
    let m = d.getMonth()
    if (m >= 7 /* August */) {
        return y + '-' + (y+1)
    } else {
        return (y-1) + '-' + y
    }
}