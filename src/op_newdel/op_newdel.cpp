#include <cstdlib>
#include <cstdint>
#include <cstdio>
#include <new>

namespace {

[[noreturn]] void oom(size_t num_bytes)
{
    fprintf(stderr, "OOM: %zu\n", num_bytes);
    exit(EXIT_FAILURE);
}

inline void * opNewImpl(size_t num_bytes) noexcept
{
    void *ptr = malloc(num_bytes);
    if (!ptr) [[unlikely]] {
        oom(num_bytes);
    }

    return ptr;
}

inline void opDeleteImpl(void *ptr) noexcept
{
    free(ptr);
}

inline void * opNewAlignImpl(size_t num_bytes, std::align_val_t al) noexcept
{
    size_t alignment = static_cast<size_t>(al);
    if (alignment < sizeof(void *)) {
        alignment = sizeof(void *);
    }

    static_assert(sizeof(al) == sizeof(size_t));
    void *ptr = aligned_alloc(alignment, num_bytes);
    if (!ptr) [[unlikely]] {
        oom(num_bytes);
    }

    return ptr;
}

inline void opDeleteAlignImpl(void *ptr, std::align_val_t al) noexcept
{
    (void)al;
    free(ptr);
}

}

#define WEAK_SYM __attribute__((__weak__))

WEAK_SYM void * operator new(size_t num_bytes)
{
    return ::opNewImpl(num_bytes);
}

WEAK_SYM void operator delete(void *ptr) noexcept
{
    ::opDeleteImpl(ptr);
}

WEAK_SYM void * operator new(
    size_t num_bytes, const std::nothrow_t &) noexcept
{
    return ::opNewImpl(num_bytes);
}

WEAK_SYM void operator delete(
    void *ptr, const std::nothrow_t &) noexcept
{
    ::opDeleteImpl(ptr);
}

WEAK_SYM void * operator new[](size_t num_bytes)
{
    return ::opNewImpl(num_bytes);
}

WEAK_SYM void operator delete[](void *ptr) noexcept
{
    ::opDeleteImpl(ptr);
}

WEAK_SYM void * operator new[](
    size_t num_bytes, const std::nothrow_t &) noexcept
{
    return ::opNewImpl(num_bytes);
}

WEAK_SYM void operator delete[](
    void *ptr, const std::nothrow_t &) noexcept
{
    ::opDeleteImpl(ptr);
}

// Aligned versions

WEAK_SYM void * operator new(size_t num_bytes, std::align_val_t al)
{
    return ::opNewAlignImpl(num_bytes, al);
}

WEAK_SYM void operator delete(void *ptr, std::align_val_t al) noexcept
{
    ::opDeleteAlignImpl(ptr, al);
}

WEAK_SYM void * operator new(
    size_t num_bytes, std::align_val_t al, const std::nothrow_t &) noexcept
{
    return ::opNewAlignImpl(num_bytes, al);
}

WEAK_SYM void operator delete(
    void *ptr, std::align_val_t al, const std::nothrow_t &) noexcept
{
    ::opDeleteAlignImpl(ptr, al);
}

WEAK_SYM void * operator new[](size_t num_bytes, std::align_val_t al)
{
    return ::opNewAlignImpl(num_bytes, al);
}

WEAK_SYM void operator delete[](void *ptr, std::align_val_t al) noexcept
{
    ::opDeleteAlignImpl(ptr, al);
}

WEAK_SYM void * operator new[](
    size_t num_bytes, std::align_val_t al, const std::nothrow_t &) noexcept
{
    return ::opNewAlignImpl(num_bytes, al);
}

WEAK_SYM void operator delete[](
    void *ptr, std::align_val_t al, const std::nothrow_t &) noexcept
{
    ::opDeleteAlignImpl(ptr, al);
}
