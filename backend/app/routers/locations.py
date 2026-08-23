from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import crud, models, schemas
from app.database import get_db

router = APIRouter(prefix="/locations", tags=["locations"])


@router.get("/", response_model=List[schemas.ServiceLocationOut])
def get_all_locations(db: Session = Depends(get_db)):
    """Get all supported service locations."""
    return crud.get_locations(db)


@router.get("/districts", response_model=List[str])
def get_districts(db: Session = Depends(get_db)):
    """Get list of distinct districts (e.g. Bengaluru Urban, Dakshina Kannada, Udupi, Mysuru)."""
    return crud.get_districts(db)


@router.get("/by-district/{district}", response_model=List[schemas.ServiceLocationOut])
def get_locations_by_district(district: str, db: Session = Depends(get_db)):
    """Get all areas within a specific district."""
    locations = crud.get_locations_by_district(db, district)
    if not locations:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No locations found for district '{district}'",
        )
    return locations
