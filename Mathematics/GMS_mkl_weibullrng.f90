
#include "Config.fpp"
include 'mkl_vsl.f90'

module mod_mkl_weibullrng

 !===================================================================================85
 !---------------------------- DESCRIPTION ------------------------------------------85
 !
 !
 !
 !          Module  name:
 !                         'mod_mkl_weibullrng'
 !          
 !          Purpose:
 !                   Wrapper around Intel MKL Fortran    vdrngweibull function.
 !          History:
 !                        First implementation
 !                        Date: 05-05-2018
 !                        Time: 12:35 GMT+2
 !
 !                        Modification (adaptation to Guided Missile Simulation project). 
 !                        Date: 22-11-2018
 !                        Time: 18:32 GMT+2
 !          Version:
 !
 !                      Major: 1
 !                      Minor: 0
 !                      Micro: 0
 !
 !          Author:  
 !                  Bernard Gingold
 !                 
 !          References:
 !         
 !                 Intel MKL library manual. 
 !    
 !         
 !          E-mail:
 !                  
 !                      beniekg@gmail.com
 !==================================================================================85
    ! Tab:5 col - Type and etc.. definitions
    ! Tab:10,11 col - Type , function and subroutine code blocks.
    
    use mod_kinds, only : int1, int4, dp
    use mkl_vsl_types
    use mkl_vsl
    implicit none
    private
    
    !=====================================================59
    !  File and module information:
    !  version,creation and build date, author,description
    !=====================================================59
    
    ! Major version
    integer(kind=int4), parameter, public :: MOD_MKL_WEIBULLRNG_MAJOR = 1_int4
    
    ! Minor version
    integer(kind=int4), parameter, public :: MOD_MKL_WEIBULLRNG_MINOR = 0_int4
    
    ! Micro version
    integer(kind=int4), parameter, public :: MOD_MKL_WEIBULLRNG_MICRO = 0_int4
    
    ! Module full version
    integer(kind=int4), parameter, public :: MOD_MKL_WEIBULLRNG_FULLVER = 1000_int4*MOD_MKL_WEIBULLRNG_MAJOR + &
                                                                     100_int4*MOD_MKL_WEIBULLRNG_MINOR  + &
                                                                     10_int4*MOD_MKL_WEIBULLRNG_MICRO
    
    ! Module creation date
    character(*),  parameter, public :: MOD_MKL_WEIBULLRNG_CREATE_DATE = " 05-05-2018 12:40 +00200 (SAT 05 MAY 2018 GMT+2)"
    
    ! Module build date  (should be set after successful compilation date/time)
    character(*),  parameter, public :: MOD_MKL_WEIBULLRNG_BUILD_DATE = " "
    
    ! Module author info
    character(*),  parameter, public :: MOD_MKL_WEIBULLRNG_AUTHOR = "Programmer: Bernard Gingold, contact: beniekg@gmail.com"
    
    ! Module short description
    character(*),  parameter, public :: MOD_MKL_WEIBULLRNG_DESCRIPT = " Fortran 2003 wrapper around Intel MKL vdrngweibull function."
    
!DIR$ IF .NOT. DEFINED (GMS_MKL_WEIBULLRNG_ADD_PADDING)
    !DIR$ DEFINE GMS_MKL_WEIBULLRNG_ADD_PADDING = 1
!DIR$ ENDIF
    
    !=================================
    ! type: MKLWeibullRNG_t
    !=================================
    type, public :: MKLWeibullRNG_t
        
          sequence
          public
          
          integer(kind=int4) :: m_nvalues
!DIR$     IF (GMS_MKL_WEIBULLRNG_ADD_PADDING .EQ. 1)
          integer(kind=int1), dimension(0:3), private :: pad0
!DIR$     ENDIF
          integer(kind=int4) :: m_brng
!DIR$     IF (GMS_MKL_WEIBULLRNG_ADD_PADDING .EQ. 1)
          integer(kind=int1), dimension(0:3), private :: pad1
!DIR$     ENDIF
          integer(kind=int4) :: m_seed
!DIR$     IF (GMS_MKL_WEIBULLRNG_ADD_PADDING .EQ. 1)
          integer(kind=int1), dimension(0:3), private :: pad2
!DIR$     ENDIF
          integer(kind=int4) :: m_error
!DIR$     IF (GMS_MKL_WEIBULLRNG_ADD_PADDING .EQ. 1) 
          integer(kind=int1), dimension(0:3), private :: pad3
!DIR$     ENDIF
          real(kind=dp)    :: m_alpha
          
          real(kind=dp)    :: m_a
          
          real(kind=dp)    :: m_beta
!DIR$     IF (GMS_MKL_WEIBULLRNG_ADD_PADDING .EQ. 1)
          integer(kind=int1), dimension(0:7), private :: pad4
!DIR$     ENDif
            ! public in order to eliminate copying procedures
!DIR$     ATTRIBUTES ALIGN : 64 :: m_rvec
          real(kind=dp), allocatable, dimension(:) :: m_rvec
          
          contains
    
         
          
          !========================================
          !    Read/write procedures
          !========================================
          
          procedure, nopass, public :: read_state
          
          procedure, nopass, public :: write_state
          
          !=======================================
          !  Class helper procedures
          !=======================================
          
          procedure, pass(this), public :: dbg_info
          
          !======================================
          !    Generic operators
          !======================================
          
          procedure, public :: copy_assign
          
          generic :: assignment (=) => copy_assign
          
          !=========================================
          !    Computational procedures
          !=========================================
          
          procedure, pass(this), public :: compute_weibullrng1
          
          procedure, pass(this), public :: compute_weibullrng2
        
    end type MKLWeibullRNG_t
          
          interface MKLWeibullRNG_t
          
            procedure :: constructor
          
          end interface MKLWeibullRNG_t
          
    contains
    
    !=================================================!
    !  @function: constructor                                          
    !  Initialization of object state.                                          
    !  Allocation and initialization to default values
    !  of real arrays
    !  @Warning
    !            Upon detection of non-fatal error
    !            variable 'err' will be set to -1
    !            Upon detection of fatal error like
    !            failed memory allocation 'STOP'
    !            will be executed.
    !            Values of variable 'err'
    !   1) -1 -- Object built already  or invalid argument ! Not used here
    !   2) -2 -- Invalid argument (any of them)  ! Not used here
    !=================================================!
    type(MKLWeibullRNG_t) function constructor(nvalues,brng,seed,alpha,a,beta, &
                                                logging,verbose,fname,append  )
          use mod_print_error,    only : handle_fatal_memory_error
          use mod_constants,      only : pi_const,INITVAL
          integer(kind=int4),     intent(in) :: nvalues,brng,seed
          real(kind=dp),          intent(in) :: alpha,a,beta
          logical(kind=int4),     intent(in) :: logging, verbose
          character(len=*),       intent(in) :: fname
          logical(kind=int4),     intent(in) :: append
          ! Locals
          character(len=256)      :: emsg
          integer(kind=int4)      :: aerr
          ! Executable statements
          constructor%m_nvalues  = nvalues
          constructor%m_brng     = brng
          constructor%m_seed     = seed
          constructor%m_error    = -1_int4
          constructor%m_alpha    = alpha
          constructor%m_a        = a
          constructor%m_beta     = beta
          associate(n=>constructor%m_nvalues)
                 allocate(constructor%m_rvec(n), &
                          STAT=aerr,             &
                          ERRMSG=emsg )
          end associate
          if(aerr /= 0) then
              call handle_fatal_memory_error( logging,verbose,append,fname ,   &
                                             "logger: "// __FILE__ // "module: mod_mkl_weibullrng, subroutine: constructor -- Memory Allocation Failure !!", &                                                        &
                                             "module: mod_mkl_weibullrng, subroutine: constructor -- Memory Allocation Failure !!", &
                                             emsg,__LINE__ )
          end if
          constructor%m_rvec = INITVAL
    end function constructor
    
   
    

    

    

    
    !============================================
    !   Read/write procedures
    !============================================
    
    subroutine read_state(this,form,unit,ioerr)
        
          class(MKLWeibullRNG_t),       intent(in)    :: this
          character(len=*),             intent(in)    :: form
          integer(kind=int4),           intent(in)    :: unit
          integer(kind=int4),           intent(inout) :: ioerr
          ! Start of executable statements
          select case(adjustl(trim(form)))
          case ("*")
              READ(unit,*,iostat=ioerr) this
          case default
              READ(unit,adjustl(trim(form)),iostat=ioerr) this
          end select
    end subroutine read_state
    
    subroutine write_state(this,form,unit,ioerr)
          
          class(MKLWeibullRNG_t),       intent(in)    :: this
          character(len=*),             intent(in)    :: form
          integer(kind=int4),           intent(in)    :: unit
          integer(kind=int4),           intent(inout) :: ioerr
          ! Start of executable statements
          select case(adjustl(trim(form)))
          case ("*")
              WRITE(unit,*,iostat=ioerr) this
          case default
              WRITE(unit,adjustl(trim(form)),iostat=ioerr) this
          end select
    end subroutine write_state
    
    subroutine dbg_info(this)
          class(MKLWeibullRNG_t), intent(in) :: this
          print*, "======================================="
          print*, " Dump of MKLWeibullRNG_t object state   "
          print*, " Collected on: ", __DATE__,":",__LINE__
          print*, "======================================="
          print*, " m_nvalues: ", this.m_nvalues
          print*, " m_brng:    ", this.m_brng
          print*, " m_seed:    ", this.m_seed
          print*, " m_error:   ", this.m_error
          print*, " m_alpha:   ", this.m_alpha
          print*, " m_a:       ", this.m_a
          print*, " m_beta:    ", this.m_beta
          print*, " m_rvec:    ", this.m_rvec
          print*, "======================================="
    end subroutine 
    
    subroutine copy_assign(lhs,rhs)
          
          class(MKLWeibullRNG_t), intent(inout) :: lhs
          class(MKLWeibullRNG_t), intent(in)    :: rhs
          lhs.m_nvalues = rhs.m_nvalues
          lhs.m_brng    = rhs.m_brng
          lhs.m_seed    = rhs.m_seed
          lhs.m_error   = rhs.m_error
          lhs.m_alpha   = rhs.m_alpha
          lhs.m_a       = rhs.m_a
          lhs.m_beta    = rhs.m_beta
          lhs.m_rvec    = rhs.m_rvec
    end subroutine
    
    subroutine compute_weibullrng1(this,method)
           use IFPORT, only :  TRACEBACKQQ
           use mod_mkl_rng
           class(MKLWeibullRNG_t), intent(inout) :: this
           integer(kind=int4),          intent(in)    :: method
           ! Locals
!DIR$      ATTRIBUTES ALIGN : 64 :: rgen
           type(MKLRandGen_t)     :: rgen
!DIR$      ATTRIBUTES ALIGN : 64 :: cstream
           type(VSL_STREAM_STATE) :: cstream
            ! Executable statemetns
           call rgen.init_stream(method,this.m_brng,this.m_seed)
           this.m_error = rgen.m_error
           if(VSL_ERROR_OK /= this.m_error) then
                   print*, "vslnewstream failed with an error: ", this.m_error
                   call TRACEBACKQQ(STRING="vslnewstream failed",USER_EXIT_CODE=-1)
                   return
           end if
           cstream = rgen.get_stream()
           this.m_error = vdrngweibull(method,cstream,this.m_nvalues,this.m_rvec,  &
                                        this.m_alpha,this.m_a,this.m_beta  )
           if(VSL_ERROR_OK /= this.m_error) then
                   print*, "vdrngweibull failed with an error: ", this.m_error
                   call TRACEBACKQQ(STRING="vdrngweibull failed",USER_EXIT_CODE=-1)
                   return
           end if
           call rgen.deinit_stream()
           this.m_error = rgen.m_error
    end subroutine
    
    subroutine compute_weibullrng2(this,stream,method)
         use IFPORT, only :  TRACEBACKQQ
         class(MKLWeibullRNG_t),       intent(inout) :: this
         type(VSL_STREAM_STATE),       intent(inout) :: stream
         integer(kind=int4),           intent(in)    :: method
         this.m_error = vdrngweibull(method,stream,this.m_nvalues,this.m_rvec, &
                                     this.m_alpha,this.m_a, this.m_beta  )
         if(VSL_ERROR_OK /= this.m_error) then
                 print*, "vdrngweibull failed with an error: ", this.m_error
                 call TRACEBACKQQ(STRING="vdrngweibull failed",USER_EXIT_CODE=-1)
                 return
         end if
    end subroutine

end module mod_mkl_weibullrng