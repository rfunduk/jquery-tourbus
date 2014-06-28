module.exports =
  dataProp: ( possiblyFalsy, alternative ) ->
    if possiblyFalsy == null || typeof(possiblyFalsy) == 'undefined'
      return alternative
    return possiblyFalsy
  include: ( value, array ) ->
    $.inArray( value, array || [] ) != -1
