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