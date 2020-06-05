def ext_length(list):
    '''
    Calculates the length of a list
    '''
    return len(list)

def ext_pop(list):
    '''
    Pop the first element of a list
    '''
    return list.pop(0)

def ext_isEmpty(list):
    '''
    Returns a bool indicating an empty list if true
    '''
    return len(list) == 0

def ext_avg(list):
    '''
    Calculates the average of a list of values
    '''
    sum = 0
     
    for n in list:
        sum = sum + float(n)

    return sum/len(list)

def ext_print(message):
    '''
    Prints a message
    '''
    print(message)

