# 关于C++17 filesystem的一些想法

1 C库函数执行成功不会清errno,filesystem函数执行成功通常清error_code.

       The value in errno is significant only when the return value of the
       call indicated an error (i.e., -1 from most system calls; -1 or NULL
       from most library functions); a function that succeeds is allowed to
       change errno.  The value of errno is never set to zero by any system
       call or library function.

2 path.compare()

file system race
